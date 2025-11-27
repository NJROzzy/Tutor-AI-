# test_voices.py
from TTS.api import TTS
import numpy as np
from scipy.io.wavfile import write as wav_write
import os

def save_wav(path, wav, sample_rate):
    wav_np = np.array(wav, dtype=np.float32)
    wav_clipped = np.clip(wav_np, -1.0, 1.0)
    wav_int16 = (wav_clipped * 32767).astype(np.int16)
    wav_write(path, int(sample_rate), wav_int16)

def main():
    tts = TTS(
        model_name="tts_models/en/vctk/vits",
        progress_bar=False,
        gpu=False,
    )

    sample_rate = tts.synthesizer.output_sample_rate

    text = (
        "Hi, I am your friendly math teacher. "
        "Today we will solve some fun questions together."
    )

    out_dir = "voice_samples"
    os.makedirs(out_dir, exist_ok=True)

    # Try a handful of speakers (you can add/remove as you like)
    test_speakers = ["p225", "p226", "p280", "p304", "p335", "p243"]

    print("Generating samples for:", test_speakers)

    for spk in test_speakers:
        print(f"  -> {spk}")
        wav = tts.tts(text=text, speaker=spk)
        out_path = os.path.join(out_dir, f"teacher_{spk}.wav")
        save_wav(out_path, wav, sample_rate)

    print(f"Done. Check the '{out_dir}' folder for WAV files.")

if __name__ == "__main__":
    main()