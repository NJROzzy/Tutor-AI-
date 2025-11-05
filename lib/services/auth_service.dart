import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thrown for auth-related failures (login/signup).
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Thrown for child-profile API failures.
class ChildApiException implements Exception {
  final String message;
  ChildApiException(this.message);
  @override
  String toString() => message;
}

/// Simple model for a child profile.
class ChildProfile {
  final int id;
  final String name;
  final int age;
  final String gender;
  final String grade;

  const ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.grade,
  });

  factory ChildProfile.fromJson(Map<String, dynamic> j) => ChildProfile(
        id: j['id'] is int ? j['id'] as int : int.tryParse('${j['id']}') ?? 0,
        name: (j['name'] ?? '').toString(),
        age: j['age'] is int
            ? j['age'] as int
            : int.tryParse('${j['age']}') ?? 0,
        gender: (j['gender'] ?? '').toString(),
        grade: (j['grade'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'gender': gender,
        'grade': grade,
      };
}

class AuthService {
  // NOTE: 127.0.0.1 works on desktop; for mobile emulator use your LAN IP (e.g. 192.168.x.x)
  static const String _base = 'http://127.0.0.1:8000/api/';

  String? _accessToken;
  String? get accessToken => _accessToken;

  // In-memory selected child (optional convenience for your UI)
  ChildProfile? selectedChild;

  // ===== AUTH =====

  Future<void> signIn({required String email, required String password}) async {
    final normalizedEmail = email.trim().toLowerCase();
    final uri = Uri.parse('${_base}auth/login/');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': normalizedEmail, 'password': password}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      _accessToken =
          (data['token'] ?? data['access'] ?? data['key'])?.toString();
      if (_accessToken == null) {
        throw AuthException('Login succeeded but no access token returned.');
      }
      return;
    }

    throw AuthException(_extractErrorMessage(res,
        fallback: 'Login failed (${res.statusCode})'));
  }

  Future<void> signUpParent({
    required String fullName,
    required String email,
    required String password,
    String phoneNumber = '',
    String country = '',
    String timezone = '',
  }) async {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final normalizedEmail = email.trim().toLowerCase();

    // Create a unique username to avoid collisions if backend needs it
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
      // You can remove 'children' if your backend ignores it on signup
      'children': [],
    };

    final uri = Uri.parse('${_base}auth/signup/');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (res.statusCode == 201 || res.statusCode == 200) return;

    throw AuthException(_extractErrorMessage(res,
        fallback: 'Sign up failed (${res.statusCode})'));
  }

  Map<String, String> authHeaders() {
    // Your backend currently returns "token" and expects "Token <token>"
    // If you switch to JWT, change to 'Authorization': 'Bearer $_accessToken'
    if (_accessToken == null) return {'Content-Type': 'application/json'};
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Token $_accessToken',
    };
  }

  // ===== CHILD PROFILES =====
  // Assumes DRF endpoints:
  //   GET  /api/children/      -> 200 OK  [{id,name,age,gender,grade}, ...]
  //   POST /api/children/      -> 201 Created {id,name,age,gender,grade}

  Future<List<ChildProfile>> fetchChildren() async {
    final uri = Uri.parse('${_base}children/');
    final res = await http.get(uri, headers: authHeaders());

    if (res.statusCode != 200) {
      throw ChildApiException(
        _extractErrorMessage(res,
            fallback: 'Failed to fetch children (${res.statusCode})'),
      );
    }

    final body = jsonDecode(res.body);
    if (body is List) {
      return body
          .map((e) => ChildProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (body is Map && body['results'] is List) {
      // If paginated
      return (body['results'] as List)
          .map((e) => ChildProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw ChildApiException('Unexpected response for children list.');
    }
  }

  Future<ChildProfile> createChild({
    required String name,
    required int age,
    required String gender,
    required String grade,
  }) async {
    final uri = Uri.parse('${_base}children/');
    final res = await http.post(
      uri,
      headers: authHeaders(),
      body: jsonEncode({
        'name': name,
        'age': age,
        'gender': gender,
        'grade': grade,
      }),
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw ChildApiException(
        _extractErrorMessage(res,
            fallback: 'Failed to create child (${res.statusCode})'),
      );
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return ChildProfile.fromJson(body);
  }

  /// Optional helper to remember which child is active in the current session.
  void selectChild(ChildProfile child) {
    selectedChild = child;
  }

  // ===== UTIL =====

  String _extractErrorMessage(http.Response res, {required String fallback}) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map) {
        // Common DRF keys
        if (body['detail'] != null) return body['detail'].toString();
        if (body['message'] != null) return body['message'].toString();

        // Field errors: return the first error string we find
        for (final entry in body.entries) {
          final v = entry.value;
          if (v is String && v.isNotEmpty) return v;
          if (v is List && v.isNotEmpty) return v.first.toString();
        }
      } else if (body is List && body.isNotEmpty) {
        return body.first.toString();
      }
    } catch (_) {
      // fall through
    }
    return fallback;
  }
}

final authService = AuthService();
