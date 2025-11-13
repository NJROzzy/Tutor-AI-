// lib/voice/whisper_engine_web.dart

class WhisperEngine {
  bool get isReady => false;

  Future<void> init() async {
    // No-op on web – Whisper via FFI isn't available.
    // You could integrate a web STT here later.
    // ignore: avoid_print
    print('[WhisperEngine] init() called on web – not supported');
  }

  Future<void> startRecording() async {
    throw UnsupportedError('WhisperEngine is not supported on web');
  }

  Future<String> stopAndTranscribe() async {
    throw UnsupportedError('WhisperEngine is not supported on web');
  }

  void dispose() {
    // nothing
  }
}
