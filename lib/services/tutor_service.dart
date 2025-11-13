import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart'; // to use authService.authHeaders()

class TutorService {
  // 🔗 Match your backend base. If AuthService uses /api/auth/, use the same.
  static const String _base = 'http://127.0.0.1:8000/api/auth/';

  Future<String> askTutor({
    required String subject,
    required int age,
    required String message,
  }) async {
    final uri = Uri.parse('$_base/chat/');

    final res = await http.post(
      uri,
      headers: authService.authHeaders(),
      body: jsonEncode({
        'subject': subject,
        'age': age,
        'message': message,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (data['reply'] ?? '').toString();
    }

    // Error handling
    try {
      final body = jsonDecode(res.body);
      final detail = body['detail']?.toString() ?? res.body.toString();
      throw Exception('Tutor error (${res.statusCode}): $detail');
    } catch (_) {
      throw Exception('Tutor error (${res.statusCode}): ${res.body}');
    }
  }
}

final tutorService = TutorService();
