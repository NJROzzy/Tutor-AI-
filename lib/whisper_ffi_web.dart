// lib/whisper_ffi_web.dart

class WhisperFFI {
  WhisperFFI._();

  bool get isSupported => false; // important

  static Future<WhisperFFI> load() async {
    return WhisperFFI._();
  }

  void init(String modelPath) {
    // no-op on web
  }

  String transcribeWav(String wavPath) {
    // no-op on web
    return '';
  }

  void dispose() {
    // no-op
  }
}
