import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/login_page.dart';
import '../config/api_config.dart';
import '../navigation/app_navigator.dart';
import '../storage/token_storage.dart';

class ApiClient {
  final TokenStorage _storage = TokenStorage();

  static const Duration _timeout = Duration(seconds: 10);
  static bool _isRedirectingToLogin = false;

  Future<Map<String, String>> _headers({
    bool json = true,
    bool auth = true,
  }) async {
    final token = auth ? await _storage.getAccessToken() : null;

    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Uri _buildUri(String path, {Map<String, dynamic>? query}) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    if (query == null || query.isEmpty) return uri;

    final qp = <String, String>{};
    query.forEach((key, value) {
      if (value == null) return;
      qp[key] = value.toString();
    });

    return uri.replace(queryParameters: qp.isEmpty ? null : qp);
  }

  Future<void> _redirectToLogin() async {
    if (_isRedirectingToLogin) return;
    _isRedirectingToLogin = true;

    await _storage.clearAll();

    final nav = navigatorKey.currentState;
    if (nav != null) {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      _isRedirectingToLogin = false;
    });
  }

  Future<bool> _tryRefreshToken() async {
    final accessToken = await _storage.getAccessToken();
    final refreshToken = await _storage.getRefreshToken();

    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      return false;
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/refresh-token');

    try {
      final res = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'refreshToken': refreshToken,
            }),
          )
          .timeout(_timeout);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        await _storage.clearAll();
        return false;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final newAccessToken = data['accessToken'] as String?;
      final newRefreshToken = data['refreshToken'] as String?;

      if (newAccessToken == null ||
          newAccessToken.isEmpty ||
          newRefreshToken == null ||
          newRefreshToken.isEmpty) {
        await _storage.clearAll();
        return false;
      }

      await _storage.saveAccessToken(newAccessToken);
      await _storage.saveRefreshToken(newRefreshToken);

      return true;
    } catch (_) {
      await _storage.clearAll();
      return false;
    }
  }

  Future<http.Response> _sendWithRefresh(
    Future<http.Response> Function() requestBuilder, {
    bool auth = true,
  }) async {
    var response = await requestBuilder();

    if (!auth || response.statusCode != 401) {
      return response;
    }

    final refreshed = await _tryRefreshToken();
    if (!refreshed) {
      await _redirectToLogin();
      return response;
    }

    response = await requestBuilder();

    if (response.statusCode == 401) {
      await _redirectToLogin();
    }

    return response;
  }

  Future<http.Response> get(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    final url = _buildUri(path, query: query);

    return _sendWithRefresh(
      () async => http
          .get(url, headers: await _headers(auth: auth))
          .timeout(_timeout),
      auth: auth,
    );
  }

  Future<http.Response> post(
    String path,
    Object body, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    final url = _buildUri(path, query: query);

    return _sendWithRefresh(
      () async => http
          .post(
            url,
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(_timeout),
      auth: auth,
    );
  }

  Future<http.Response> postEmpty(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    final url = _buildUri(path, query: query);

    return _sendWithRefresh(
      () async => http
          .post(url, headers: await _headers(json: false, auth: auth))
          .timeout(_timeout),
      auth: auth,
    );
  }

  Future<http.Response> put(
    String path,
    Object body, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    final url = _buildUri(path, query: query);

    return _sendWithRefresh(
      () async => http
          .put(
            url,
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(_timeout),
      auth: auth,
    );
  }

  Future<http.Response> putEmpty(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    final url = _buildUri(path, query: query);

    return _sendWithRefresh(
      () async => http
          .put(url, headers: await _headers(json: false, auth: auth))
          .timeout(_timeout),
      auth: auth,
    );
  }

  Future<http.Response> deleteEmpty(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    final url = _buildUri(path, query: query);

    return _sendWithRefresh(
      () async => http
          .delete(url, headers: await _headers(json: false, auth: auth))
          .timeout(_timeout),
      auth: auth,
    );
  }

  Future<Map<String, String>> multipartHeaders() async {
    final token = await _storage.getAccessToken();

    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
}