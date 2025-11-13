#include "whisper_bridge.h"

#include <cstdint>
#include <cstring>
#include <vector>
#include <string>
#include <cstdio>
#include <cmath>
#include <mutex>
#include <memory>

#include "whisper.h"

// ---------- Context wrapper ----------

struct WhisperCtx {
  struct whisper_context* ctx = nullptr;
  std::mutex mtx;
};

// ---------- WAV loader (robust, supports many formats) ----------

// GUID for PCM / IEEE_FLOAT in WAVE_FORMAT_EXTENSIBLE
static const uint8_t KSDATAFORMAT_SUBTYPE_PCM[16] = {
  0x01,0x00,0x00,0x00,0x10,0x00,0x80,0x00,0x00,0xaa,0x00,0x38,0x9b,0x71,0x00,0x00
};
static const uint8_t KSDATAFORMAT_SUBTYPE_IEEE_FLOAT[16] = {
  0x03,0x00,0x00,0x00,0x10,0x00,0x80,0x00,0x00,0xaa,0x00,0x38,0x9b,0x71,0x00,0x00
};

static bool guidEquals(const uint8_t a[16], const uint8_t b[16]) {
  return std::memcmp(a, b, 16) == 0;
}

// Reads WAV (PCM16 / PCM24 / PCM32 / FLOAT32, incl. WAVE_FORMAT_EXTENSIBLE) and downmixes to mono float
static std::string read_wav_mono_any(const char* path, std::vector<float>& out) {
  FILE* f = std::fopen(path, "rb");
  if (!f) return "Failed to open WAV";

  auto rd = [&](void* p, size_t n) -> bool { return std::fread(p, 1, n, f) == n; };
  auto skip = [&](size_t n) { std::fseek(f, (long)n, SEEK_CUR); };

  struct Riff { char id[4]; uint32_t size; char wave[4]; } riff;
  if (!rd(&riff, sizeof(riff)) || std::strncmp(riff.id,"RIFF",4)!=0 || std::strncmp(riff.wave,"WAVE",4)!=0) {
    std::fclose(f); return "Not a RIFF/WAVE file";
  }

  uint16_t audioFormat = 0, numChannels = 0, bitsPerSample = 0, cbSize = 0;
  uint32_t sampleRate = 0;
  bool extensible = false;
  uint8_t subFormat[16] = {0};
  long dataPos = -1; uint32_t dataSize = 0;

  while (true) {
    struct Chunk { char id[4]; uint32_t size; } ch;
    if (!rd(&ch, sizeof(ch))) break;

    if (std::strncmp(ch.id, "fmt ", 4) == 0) {
      // First 16 bytes are common
      struct Fmt16 {
        uint16_t audioFormat;
        uint16_t numChannels;
        uint32_t sampleRate;
        uint32_t byteRate;
        uint16_t blockAlign;
        uint16_t bitsPerSample;
      } fmt16{};
      if (ch.size < sizeof(fmt16)) { std::fclose(f); return "Bad fmt chunk"; }
      if (!rd(&fmt16, sizeof(fmt16))) { std::fclose(f); return "Failed fmt read"; }

      audioFormat   = fmt16.audioFormat;   // 1=PCM, 3=FLOAT, 0xFFFE=EXTENSIBLE
      numChannels   = fmt16.numChannels;
      sampleRate    = fmt16.sampleRate;
      bitsPerSample = fmt16.bitsPerSample;

      // If more bytes, read cbSize then possibly extensible fields
      size_t remaining = ch.size - sizeof(fmt16);
      // if (remaining >= 2) {
      //   if (!rd(&cbSize, 2)) { std::fclose(f); return "Failed fmt cbSize"; }
      //   remaining -= 2;
      //   if (audioFormat == 0xFFFE && remaining >= 22) {
      //     // WAVE_FORMAT_EXTENSIBLE: read validBitsPerSample, channelMask, subFormat GUID
      //     uint16_t validBitsPerSample; uint32_t channelMask; uint8_t guid[16];
      //     if (!rd(&validBitsPerSample, 2) || !rd(&channelMask, 4) || !rd(guid, 16)) {
      //       std::fclose(f); return "Failed fmt extensible";
      //     }
      //     std::memcpy(subFormat, guid, 16);
      //     extensible = true;
      //     // Prefer validBitsPerSample if provided
      //     if (validBitsPerSample) bitsPerSample = validBitsPerSample;
      //     remaining -= 22;
      //   }
      // }
      if (remaining) skip(remaining);

    } else if (std::strncmp(ch.id, "data", 4) == 0) {
      dataPos = std::ftell(f);
      dataSize = ch.size;
      skip(ch.size);
    } else {
      skip(ch.size); // JUNK/LIST/fact/…
    }
  }

  if (dataPos < 0) { std::fclose(f); return "No data chunk"; }
  if (numChannels < 1) { std::fclose(f); return "No channels"; }
  if (sampleRate == 0) { std::fclose(f); return "Bad sampleRate"; }

    // Determine effective format
  bool isFloat = false, isPCM = false;
  if (audioFormat == 1) { // PCM
    isPCM = true;
  } else if (audioFormat == 3) { // IEEE float
    isFloat = true;
  } else if (audioFormat == 0xFFFE) {
    // WAVE_FORMAT_EXTENSIBLE – on macOS we’ll be forgiving:
    // if the bit depth looks like PCM, treat as PCM; if 32-bit and not PCM, treat as float.
    if (bitsPerSample == 16 || bitsPerSample == 24 || bitsPerSample == 32) {
      isPCM = true;
    } else if (bitsPerSample == 32) {
      isFloat = true;
    } else {
      std::fclose(f);
      return "Unsupported extensible bit depth";
    }
  } else {
    std::fclose(f);
    return "Unsupported WAV format tag";
  }

  // Read raw payload
  std::fseek(f, dataPos, SEEK_SET);
  out.clear();

  if (isFloat && bitsPerSample == 32) {
    // FLOAT32
    const size_t count = dataSize / 4;
    std::vector<float> buf(count);
    if (!rd(buf.data(), dataSize)) { std::fclose(f); return "Failed float32 read"; }
    std::fclose(f);
    if (numChannels == 1) {
      out = std::move(buf);
    } else {
      const size_t frames = count / numChannels;
      out.resize(frames);
      for (size_t i = 0; i < frames; ++i) {
        float acc = 0.f;
        for (uint16_t c = 0; c < numChannels; ++c) acc += buf[i*numChannels + c];
        out[i] = acc / (float)numChannels;
      }
    }
    // clamp
    for (auto &v : out) { if (v > 1.f) v = 1.f; else if (v < -1.f) v = -1.f; }
    return "";
  }

  if (isPCM && (bitsPerSample == 16 || bitsPerSample == 24 || bitsPerSample == 32)) {
    // Read bytes then convert to float
    std::vector<uint8_t> bytes(dataSize);
    if (!rd(bytes.data(), dataSize)) { std::fclose(f); return "Failed PCM read"; }
    std::fclose(f);

    auto readS16 = [&](size_t i)->int16_t {
      int16_t v = (int16_t)(bytes[i] | (bytes[i+1] << 8));
      return v;
    };
    auto readS24 = [&](size_t i)->int32_t {
      // little-endian 24-bit -> sign-extend to 32
      int32_t v = (bytes[i] | (bytes[i+1] << 8) | (bytes[i+2] << 16));
      if (v & 0x00800000) v |= 0xFF000000;
      return v;
    };
    auto readS32 = [&](size_t i)->int32_t {
      int32_t v = (int32_t)(bytes[i] | (bytes[i+1] << 8) | (bytes[i+2] << 16) | (bytes[i+3] << 24));
      return v;
    };

    const size_t bytesPerSample = bitsPerSample / 8;
    const size_t totalSamples   = dataSize / bytesPerSample;
    const size_t frames         = totalSamples / numChannels;
    out.resize(frames);

    if (bitsPerSample == 16) {
      for (size_t i = 0; i < frames; ++i) {
        int32_t acc = 0;
        for (uint16_t c = 0; c < numChannels; ++c) {
          const size_t off = (i*numChannels + c) * 2;
          acc += readS16(off);
        }
        out[i] = (float)acc / (32768.0f * numChannels);
      }
    } else if (bitsPerSample == 24) {
      for (size_t i = 0; i < frames; ++i) {
        int64_t acc = 0;
        for (uint16_t c = 0; c < numChannels; ++c) {
          const size_t off = (i*numChannels + c) * 3;
          acc += readS24(off);
        }
        // 24-bit full-scale is 2^23
        out[i] = (float)acc / ((float)(1 << 23) * (float)numChannels);
      }
    } else { // 32-bit PCM
      for (size_t i = 0; i < frames; ++i) {
        int64_t acc = 0;
        for (uint16_t c = 0; c < numChannels; ++c) {
          const size_t off = (i*numChannels + c) * 4;
          acc += readS32(off);
        }
        out[i] = (float)acc / (2147483648.0f * (float)numChannels); // 2^31
      }
    }
    return "";
  }

  return "Unsupported WAV format (need PCM16/24/32 or FLOAT32)";
}

// Optional: tiny auto-gain for very quiet audio
static void auto_gain(std::vector<float>& pcm) {
  float maxabs = 0.f;
  for (float v : pcm) {
    float a = std::fabs(v);
    if (a > maxabs) maxabs = a;
  }
  if (maxabs > 0.f && maxabs < 0.01f) {
    float g = std::min(100.f, 0.02f / maxabs);
    for (auto &v : pcm) v *= g;
  }
}

// ---------- C API exported for Dart FFI ----------

extern "C" {

whisper_handle_t whisper_bridge_init(const char* model_path) {
  auto* w = new WhisperCtx();

  whisper_context_params wcparams = whisper_context_default_params();
  // wcparams.use_gpu = false; // keep default; Metal backend is auto if enabled

  w->ctx = whisper_init_from_file_with_params(model_path, wcparams);
  if (!w->ctx) {
    delete w;
    return nullptr;
  }
  return reinterpret_cast<whisper_handle_t>(w);
}

const char* whisper_bridge_transcribe_wav(whisper_handle_t h, const char* wav_path) {
  if (!h) return nullptr;
  auto* w = reinterpret_cast<WhisperCtx*>(h);

  std::lock_guard<std::mutex> lock(w->mtx);

  std::vector<float> pcm;
  std::string err = read_wav_mono_any(wav_path, pcm);
  if (!err.empty()) {
    char* out = (char*)std::malloc(err.size() + 1);
    std::memcpy(out, err.c_str(), err.size() + 1);
    return out;
  }

  if (pcm.empty()) {
    const char* msg = "No audio samples";
    char* out = (char*)std::malloc(std::strlen(msg)+1);
    std::strcpy(out, msg);
    return out;
  }

  auto_gain(pcm);

  auto params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
  params.translate     = false;
  params.language      = "en";   // or "auto"
  params.n_threads     = 4;
  params.no_timestamps = true;

  if (whisper_full(w->ctx, params, pcm.data(), (int)pcm.size()) != 0) {
    const char* msg = "Transcription failed";
    char* out = (char*)std::malloc(std::strlen(msg)+1);
    std::strcpy(out, msg);
    return out;
  }

  // Stitch segments into a single string
  std::string text;
  const int n = whisper_full_n_segments(w->ctx);
  text.reserve(128);
  for (int i = 0; i < n; ++i) {
    const char* seg = whisper_full_get_segment_text(w->ctx, i);
    if (seg) text += seg;
  }

  char* out = static_cast<char*>(std::malloc(text.size() + 1));
  std::memcpy(out, text.c_str(), text.size() + 1);
  return out;
}

void whisper_bridge_free_str(const char* p) {
  if (p) std::free(const_cast<char*>(p));
}

void whisper_bridge_free(whisper_handle_t h) {
  if (!h) return;
  auto* w = reinterpret_cast<WhisperCtx*>(h);
  if (w->ctx) whisper_free(w->ctx);
  delete w;
}

} // extern "C"