// lib/voice/whisper_engine.dart
export 'whisper_engine_io.dart' if (dart.library.js) 'whisper_engine_web.dart';

// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'package:record/record.dart';

// import '../whisper_ffi.dart';
// import '../utils/model_loader.dart';

// // lib/voice/whisper_engine.dart

// export 'whisper_engine_io.dart'
//     if (dart.library.html) 'whisper_engine_web.dart';

// class WhisperEngine {
//   final AudioRecorder _rec = AudioRecorder();
//   WhisperFFI? _ffi;
//   bool _ready = false;

//   late String _lastWavPath; // set before use

//   bool get isReady => _ready;

//   /// Initialize Whisper (copies model asset to disk, loads dylib)
//   Future<void> init() async {
//     try {
//       final modelPath =
//           await prepareModel(); // assets/models/tiny.en.bin -> real path
//       _ffi = await WhisperFFI.load();
//       _ffi!.init(modelPath);
//       _ready = true;
//       // ignore: avoid_print
//       print('[WhisperEngine] init OK: $modelPath');
//     } catch (e) {
//       _ready = false;
//       // ignore: avoid_print
//       print('[WhisperEngine] init FAILED: $e');
//       rethrow;
//     }
//   }

//   Future<void> startRecording() async {
//     if (!_ready) throw Exception('Whisper not initialized');
//     final has = await _rec.hasPermission();
//     if (!has) throw Exception('Mic permission denied');

//     final dir = await getTemporaryDirectory();
//     _lastWavPath = '${dir.path}/rec16k.wav';
//     final f = File(_lastWavPath);
//     if (await f.exists()) await f.delete();

//     // Some macs need explicit encoder/sampleRate/channels
//     await _rec.start(
//       const RecordConfig(
//         encoder: AudioEncoder.wav, // 16-bit PCM
//         sampleRate: 16000,
//         numChannels: 1,
//       ),
//       path: _lastWavPath,
//     );

//     // ignore: avoid_print
//     print('[WhisperEngine] Recording -> $_lastWavPath');
//   }

//   Future<String> stopAndTranscribe() async {
//     try {
//       final path =
//           await _rec.stop(); // returns path (nullable on some platforms)
//       // ignore: avoid_print
//       print(
//           '[WhisperEngine] stop() returned path=$path, expected=$_lastWavPath');

//       final file = File(_lastWavPath);
//       if (!await file.exists()) {
//         throw Exception('Recorded file not found at $_lastWavPath');
//       }
//       final size = await file.length();
//       // ignore: avoid_print
//       print('[WhisperEngine] recorded bytes=$size');

//       if (size < 2000) {
//         // tiny file = almost silence/too short
//         return '(No audio captured – try speaking for 2–3 seconds and press Stop)';
//       }

//       if (_ffi == null) throw Exception('FFI not ready');

//       final text = _ffi!.transcribeWav(_lastWavPath);
//       // ignore: avoid_print
//       print('[WhisperEngine] transcript="${text.replaceAll('\n', ' ')}"');

//       if (text.trim().isEmpty) {
//         return '(No words recognized – try again closer to the mic)';
//       }
//       return text;
//     } catch (e) {
//       // ignore: avoid_print
//       print('[WhisperEngine] transcribe error: $e');
//       return 'Transcription error: $e';
//     }
//   }

//   void dispose() {
//     _ffi?.dispose();
//   }
// }
