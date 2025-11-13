// // lib/whisper_ffi.dart
// import 'dart:ffi' as ffi;
// import 'dart:io';
// import 'package:ffi/ffi.dart';

// typedef _init_native = ffi.Pointer<ffi.Void> Function(ffi.Pointer<Utf8>);
// typedef _init_dart = ffi.Pointer<ffi.Void> Function(ffi.Pointer<Utf8>);
// typedef _trans_native = ffi.Pointer<Utf8> Function(
//     ffi.Pointer<ffi.Void>, ffi.Pointer<Utf8>);
// typedef _trans_dart = ffi.Pointer<Utf8> Function(
//     ffi.Pointer<ffi.Void>, ffi.Pointer<Utf8>);
// typedef _free_str_native = ffi.Void Function(ffi.Pointer<Utf8>);
// typedef _free_str_dart = void Function(ffi.Pointer<Utf8>);
// typedef _free_native = ffi.Void Function(ffi.Pointer<ffi.Void>);
// typedef _free_dart = void Function(ffi.Pointer<ffi.Void>);

// class WhisperFFI {
//   late final ffi.DynamicLibrary _lib;
//   late final _init_dart _init;
//   late final _trans_dart _transcribeWav;
//   late final _free_str_dart _freeStr;
//   late final _free_dart _free;

//   ffi.Pointer<ffi.Void>? _handle;

//   WhisperFFI._();

//   static Future<WhisperFFI> load() async {
//     final w = WhisperFFI._();

//     if (Platform.isMacOS || Platform.isIOS) {
//       // Static link: symbols are in the current process
//       w._lib = ffi.DynamicLibrary.process();
//     } else if (Platform.isAndroid || Platform.isLinux) {
//       w._lib = ffi.DynamicLibrary.open('libwhisper.so');
//     } else if (Platform.isWindows) {
//       w._lib = ffi.DynamicLibrary.open('whisper.dll');
//     } else {
//       throw UnsupportedError('Unsupported platform for Whisper');
//     }

//     w._init =
//         w._lib.lookupFunction<_init_native, _init_dart>('whisper_bridge_init');
//     w._transcribeWav = w._lib.lookupFunction<_trans_native, _trans_dart>(
//         'whisper_bridge_transcribe_wav');
//     w._freeStr = w._lib.lookupFunction<_free_str_native, _free_str_dart>(
//         'whisper_bridge_free_str');
//     w._free =
//         w._lib.lookupFunction<_free_native, _free_dart>('whisper_bridge_free');
//     return w;
//   }

//   void init(String modelPath) {
//     final mp = modelPath.toNativeUtf8();
//     try {
//       _handle = _init(mp);
//     } finally {
//       malloc.free(mp);
//     }
//     if (_handle == ffi.nullptr) {
//       _handle = null;
//       throw Exception('Failed to init whisper with model: $modelPath');
//     }
//   }

//   String transcribeWav(String wavPath) {
//     final h = _handle;
//     if (h == null) throw Exception('Whisper not initialized');

//     final pWav = wavPath.toNativeUtf8();
//     ffi.Pointer<Utf8> cstr;
//     try {
//       cstr = _transcribeWav(h, pWav);
//     } finally {
//       malloc.free(pWav);
//     }

//     if (cstr.address == 0) return '';
//     final text = cstr.toDartString();
//     _freeStr(cstr);
//     return text;
//   }

//   void dispose() {
//     final h = _handle;
//     if (h != null) {
//       _free(h);
//       _handle = null;
//     }
//   }
// }
//..........................\
// lib/whisper_ffi_native.dart
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
// import 'dart:io';
// import 'package:permission_handler/permission_handler.dart';

typedef _init_native = ffi.Pointer<ffi.Void> Function(ffi.Pointer<Utf8>);
typedef _init_dart = ffi.Pointer<ffi.Void> Function(ffi.Pointer<Utf8>);
typedef _trans_native = ffi.Pointer<Utf8> Function(
    ffi.Pointer<ffi.Void>, ffi.Pointer<Utf8>);
typedef _trans_dart = ffi.Pointer<Utf8> Function(
    ffi.Pointer<ffi.Void>, ffi.Pointer<Utf8>);
typedef _free_str_native = ffi.Void Function(ffi.Pointer<Utf8>);
typedef _free_str_dart = void Function(ffi.Pointer<Utf8>);
typedef _free_native = ffi.Void Function(ffi.Pointer<ffi.Void>);
typedef _free_dart = void Function(ffi.Pointer<ffi.Void>);

class WhisperFFI {
  late final ffi.DynamicLibrary _lib;
  late final _init_dart _init;
  late final _trans_dart _transcribeWav;
  late final _free_str_dart _freeStr;
  late final _free_dart _free;

  ffi.Pointer<ffi.Void>? _handle;

  WhisperFFI._();

  bool get isSupported => true;

  static Future<WhisperFFI> load() async {
    final w = WhisperFFI._();

    if (Platform.isMacOS || Platform.isIOS) {
      w._lib = ffi.DynamicLibrary.process();
    } else if (Platform.isAndroid || Platform.isLinux) {
      w._lib = ffi.DynamicLibrary.open('libwhisper.so');
    } else if (Platform.isWindows) {
      w._lib = ffi.DynamicLibrary.open('whisper.dll');
    } else {
      throw UnsupportedError('Unsupported platform for Whisper');
    }

    w._init =
        w._lib.lookupFunction<_init_native, _init_dart>('whisper_bridge_init');
    w._transcribeWav = w._lib.lookupFunction<_trans_native, _trans_dart>(
        'whisper_bridge_transcribe_wav');
    w._freeStr = w._lib.lookupFunction<_free_str_native, _free_str_dart>(
        'whisper_bridge_free_str');
    w._free =
        w._lib.lookupFunction<_free_native, _free_dart>('whisper_bridge_free');

    return w;
  }

  void init(String modelPath) {
    final mp = modelPath.toNativeUtf8();
    try {
      _handle = _init(mp);
    } finally {
      malloc.free(mp);
    }
    if (_handle == ffi.nullptr) {
      _handle = null;
      throw Exception('Failed to init whisper with model: $modelPath');
    }
  }

  String transcribeWav(String wavPath) {
    final h = _handle;
    if (h == null) throw Exception('Whisper not initialized');

    final pWav = wavPath.toNativeUtf8();
    ffi.Pointer<Utf8> cstr;
    try {
      cstr = _transcribeWav(h, pWav);
    } finally {
      malloc.free(pWav);
    }

    if (cstr.address == 0) return '';
    final text = cstr.toDartString();
    _freeStr(cstr);
    return text;
  }

  void dispose() {
    final h = _handle;
    if (h != null) {
      _free(h);
      _handle = null;
    }
  }
}
