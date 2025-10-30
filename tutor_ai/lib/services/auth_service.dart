import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  static const String _base = 'http://127.0.0.1:8000/api/'; // macOS desktop

  String? _accessToken;
  String? get accessToken => _accessToken;

  Future<void> signIn({required String email, required String password}) async {
    final normalizedEmail = email.trim().toLowerCase(); // ✅ normalize
    final uri = Uri.parse('${_base}auth/login/');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': normalizedEmail, 'password': password}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      _accessToken = data['token'] as String?;
      if (_accessToken == null) {
        throw AuthException('Login succeeded but no access token returned.');
      }
      return;
    }

    // ✅ bubble up server message (helps debug 401/400)
    String msg = 'Login failed (${res.statusCode})';
    try {
      final body = jsonDecode(res.body);
      msg = body['detail']?.toString() ??
          body['message']?.toString() ??
          res.body.toString();
    } catch (_) {}
    throw AuthException(msg);
  }

  Future<void> signUpParent({
    required String fullName,
    required String email,
    required String password,
    String phoneNumber = '',
    String country = '',
    String timezone = '',
  }) async {
    // ✅ split full name safely
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    // ✅ normalize email
    final normalizedEmail = email.trim().toLowerCase();

    // ✅ unique username (avoids "taken" errors)
    final local = normalizedEmail
        .split('@')
        .first
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final username = '${local}_${DateTime.now().millisecondsSinceEpoch}';

    final payload = {
      'first_name': firstName,
      'last_name': lastName,
      'email': normalizedEmail,
      'phone_number': phoneNumber,
      'username': username,
      'password': password,
      'country': country,
      'timezone': timezone,
      // send empty list for now; add child UI later
      'children': [],
    };

    final uri = Uri.parse('${_base}auth/signup/');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (res.statusCode == 201 || res.statusCode == 200) return;

    // ✅ show exact backend errors (e.g., field errors)
    String msg = 'Sign up failed (${res.statusCode})';
    try {
      final body = jsonDecode(res.body);
      // collect first error we find
      msg = body['detail']?.toString() ??
          body['message']?.toString() ??
          body['email']?.toString() ??
          body['username']?.toString() ??
          res.body.toString();
    } catch (_) {}
    throw AuthException(msg);
  }

  Map<String, String> authHeaders() {
    if (_accessToken == null) return {'Content-Type': 'application/json'};
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Token $_accessToken',
    };
  }
}

final authService = AuthService();
