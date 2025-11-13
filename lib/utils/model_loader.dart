import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

Future<String> prepareModel() async {
  // load model bytes from Flutter asset
  final data = await rootBundle.load('assets/models/tiny.en.bin');
  // copy it into Application Support dir
  final dir = await getApplicationSupportDirectory();
  final file = File('${dir.path}/tiny.en.bin');

  if (!await file.exists()) {
    await file.create(recursive: true);
    await file.writeAsBytes(data.buffer.asUint8List());
  }
  return file.path; // absolute path for whisper_bridge_init()
}
