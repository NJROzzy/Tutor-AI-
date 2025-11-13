// lib/voice/whisper_engine_io.dart
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:ffi/ffi.dart';

import '../whisper_ffi.dart';
import '../utils/model_loader.dart';

class WhisperEngine {
  final AudioRecorder _rec = AudioRecorder();
  WhisperFFI? _ffi;
  bool _ready = false;

  late String _lastWavPath;

  bool get isReady => _ready;

  Future<void> init() async {
    try {
      final modelPath = await prepareModel();
      _ffi = await WhisperFFI.load();
      _ffi!.init(modelPath);
      _ready = true;
      print('[WhisperEngine] init OK: $modelPath');
    } catch (e) {
      _ready = false;
      print('[WhisperEngine] init FAILED: $e');
      rethrow;
    }
  }

  Future<void> startRecording() async {
    if (!_ready) throw Exception('Mic permission denied');

    final has = await _rec.hasPermission();
    if (!has) throw Exception('Mic permission denied for recorder');

    final dir = await getTemporaryDirectory();
    _lastWavPath = '${dir.path}/rec16k.wav';

    final f = File(_lastWavPath);
    if (await f.exists()) await f.delete();

    await _rec.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: _lastWavPath,
    );

    print('[WhisperEngine] Recording -> $_lastWavPath');
  }

  Future<String> stopAndTranscribe() async {
    try {
      final path = await _rec.stop();
      print(
          '[WhisperEngine] stop() returned path=$path, expected=$_lastWavPath');

      final file = File(_lastWavPath);
      if (!await file.exists()) {
        throw Exception('Recorded file not found at $_lastWavPath');
      }

      final size = await file.length();
      print('[WhisperEngine] recorded bytes=$size');

      if (size < 2000) {
        return '(No audio captured – try speaking for 2–3 seconds and press Stop)';
      }

      if (_ffi == null) throw Exception('FFI not ready');

      final text = _ffi!.transcribeWav(_lastWavPath);
      print('[WhisperEngine] transcript="${text.replaceAll('\n', ' ')}"');

      if (text.trim().isEmpty) {
        return '(No words recognized – try again closer to the mic)';
      }
      return text;
    } catch (e) {
      print('[WhisperEngine] transcribe error: $e');
      return 'Transcription error: $e';
    }
  }

  void dispose() {
    _ffi?.dispose();
  }
}
