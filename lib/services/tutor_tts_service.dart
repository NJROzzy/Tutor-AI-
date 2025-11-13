import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class TutorTtsService {
  static const String _baseUrl = 'http://127.0.0.1:8000/api/auth/tutor/tts/';

  /// Sends text to Django TTS endpoint, saves WAV to a temp file,
  /// and returns the file path.
  Future<String> synthesizeToFile(String text) async {
    final uri = Uri.parse(_baseUrl);

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );

    if (res.statusCode != 200) {
      throw Exception(
        'TTS failed (${res.statusCode}): ${res.body}',
      );
    }

    // 1) Get raw WAV bytes from backend
    final bytes = res.bodyBytes;

    // 2) Save them to a .wav file in the temp directory
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/tutor_tts_${DateTime.now().millisecondsSinceEpoch}.wav',
    );
    await file.writeAsBytes(bytes, flush: true);

    // 3) Return path for audioplayers
    return file.path;
  }
}

final tutorTtsService = TutorTtsService();
