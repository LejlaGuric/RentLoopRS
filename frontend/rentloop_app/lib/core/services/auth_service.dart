import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class LoginResult {
  final String token;
  final int userId;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final int roleId; // 1 Admin, 2 Client

  const LoginResult({
    required this.token,
    required this.userId,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.roleId,
  });

  bool get isAdmin => roleId == 1;
  bool get isClient => roleId == 2;
}

class AuthService {
  final TokenStorage _storage = TokenStorage();

  Future<LoginResult> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/login');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'usernameOrEmail': usernameOrEmail,
        'password': password,
      }),
    );

    // tvoje API vraća string poruke za 400/401
    if (res.statusCode == 400) {
      throw Exception(_cleanMessage(res.body));
    }
    if (res.statusCode == 401) {
      throw Exception(_cleanMessage(res.body.isEmpty ? 'Invalid credentials.' : res.body));
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Greška servera (${res.statusCode}).');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final token = data['token'] as String?;

    if (token == null || token.isEmpty) {
      throw Exception('Server nije vratio token.');
    }

    final user = data['user'] as Map<String, dynamic>;

    final result = LoginResult(
      token: token,
      userId: (user['id'] as num).toInt(),
      username: (user['username'] ?? '') as String,
      email: (user['email'] ?? '') as String,
      firstName: (user['firstName'] ?? '') as String,
      lastName: (user['lastName'] ?? '') as String,
      roleId: (user['role'] as num).toInt(),
    );

    // ✅ KLJUČNO: spremi token (već imaš - ostaje)
    await _storage.saveToken(token);

    return result;
  }

    Future<void> register({
    required String username,
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
    String address = '',
    String phone = '',
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/register');

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'address': address,
        'phone': phone,
      }),
    );

    if (res.statusCode == 400) {
      throw Exception(_cleanMessage(res.body));
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_cleanMessage(res.body.isEmpty ? 'Greška servera (${res.statusCode}).' : res.body));
    }

    // backend vraća: { message: "Registered successfully." }
    return;
  }

    Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/change-password');

    final headers = await authHeaders();

    final res = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (res.statusCode == 400) {
      throw Exception(_cleanMessage(res.body));
    }
    if (res.statusCode == 401) {
      throw Exception('Niste autorizovani.');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Greška servera (${res.statusCode}).');
    }
  }



  Future<void> logout() async {
    await _storage.clearToken();
  }

  Future<String?> getToken() async {
    return _storage.getToken();
  }

  // ✅ NEW: brzo provjeri da li je user ulogovan
  Future<bool> isLoggedIn() async {
    final t = await _storage.getToken();
    return t != null && t.isNotEmpty;
  }

  // ✅ NEW: standard headeri za auth pozive (Bearer)
  Future<Map<String, String>> authHeaders() async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) return {'Content-Type': 'application/json'};
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ✅ OPTIONAL: čitanje userId iz JWT-a (korisno za debug/UI, nije obavezno)
  int? getUserIdFromTokenSync(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded) as Map<String, dynamic>;

      // backend obično koristi ClaimTypes.NameIdentifier ili "sub"
      final v = map['nameid'] ?? map['sub'] ?? map['userid'];
      if (v == null) return null;

      return int.tryParse(v.toString());
    } catch (_) {
      return null;
    }
  }

  String _cleanMessage(String msg) {
    // backend ti vraća plain text (npr. "UsernameOrEmail is required.")
    return msg.replaceAll('"', '').trim();
  }
}
