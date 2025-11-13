#pragma once
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif



__attribute__((visibility("default"))) void* whisper_bridge_init(const char* model_path);
__attribute__((visibility("default"))) const char* whisper_bridge_transcribe_wav(void* handle, const char* wav_path);
__attribute__((visibility("default"))) void whisper_bridge_free_str(const char* p);
__attribute__((visibility("default"))) void whisper_bridge_free(void* handle);

typedef void* whisper_handle_t;

// Returns NULL on failure; otherwise a non-null opaque handle.
// model_path: absolute path to the .bin model (e.g., base.en.bin)
whisper_handle_t whisper_bridge_init(const char* model_path);

// Transcribes a 16-bit PCM WAV file (mono) and returns a newly allocated UTF-8 C string.
// Caller must free with whisper_bridge_free_str.
const char* whisper_bridge_transcribe_wav(whisper_handle_t h, const char* wav_path);

// Frees the returned transcription string
void whisper_bridge_free_str(const char* p);

// Destroys the handle and frees resources
void whisper_bridge_free(whisper_handle_t h);

#ifdef __cplusplus
}
#endif
