import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class LoginResult {
  final String accessToken;
  final String refreshToken;
  final int userId;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final int roleId; // 1 Admin, 2 Client

  const LoginResult({
    required this.accessToken,
    required this.refreshToken,
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

    if (res.statusCode == 400) {
      throw Exception(_cleanMessage(res.body));
    }
    if (res.statusCode == 401) {
      throw Exception(_cleanMessage(
        res.body.isEmpty ? 'Invalid credentials.' : res.body,
      ));
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Greška servera (${res.statusCode}).');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Server nije vratio access token.');
    }

    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('Server nije vratio refresh token.');
    }

    final user = data['user'] as Map<String, dynamic>;

    final result = LoginResult(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: (user['id'] as num).toInt(),
      username: (user['username'] ?? '') as String,
      email: (user['email'] ?? '') as String,
      firstName: (user['firstName'] ?? '') as String,
      lastName: (user['lastName'] ?? '') as String,
      roleId: (user['role'] as num).toInt(),
    );

    await _storage.saveAccessToken(accessToken);
    await _storage.saveRefreshToken(refreshToken);

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
      throw Exception(_cleanMessage(
        res.body.isEmpty ? 'Greška servera (${res.statusCode}).' : res.body,
      ));
    }

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
    await _storage.clearAll();
  }

  Future<String?> getAccessToken() async {
    return _storage.getAccessToken();
  }

  Future<String?> getRefreshToken() async {
    return _storage.getRefreshToken();
  }

  Future<bool> isLoggedIn() async {
    final t = await _storage.getAccessToken();
    return t != null && t.isNotEmpty;
  }

  Future<Map<String, String>> authHeaders() async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      return {'Content-Type': 'application/json'};
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  int? getUserIdFromTokenSync(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded) as Map<String, dynamic>;

      final v = map['nameid'] ??
          map['sub'] ??
          map['userid'] ??
          map['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'];

      if (v == null) return null;

      return int.tryParse(v.toString());
    } catch (_) {
      return null;
    }
  }

  String _cleanMessage(String msg) {
    return msg.replaceAll('"', '').trim();
  }
}