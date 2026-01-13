import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class ApiClient {
  final TokenStorage _storage = TokenStorage();

  static const Duration _timeout = Duration(seconds: 10);

  Future<Map<String, String>> _headers({
    bool json = true,
    bool auth = true,
  }) async {
    final token = auth ? await _storage.getToken() : null;

    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
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

  // ✅ GET
  Future<http.Response> get(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    final url = _buildUri(path, query: query);
    return http.get(url, headers: await _headers(auth: auth)).timeout(_timeout);
  }

  // ✅ POST JSON
  Future<http.Response> post(
    String path,
    Object body, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    final url = _buildUri(path, query: query);
    return http
        .post(url, headers: await _headers(auth: auth), body: jsonEncode(body))
        .timeout(_timeout);
  }

  // ✅ POST bez body (npr. log view)
  Future<http.Response> postEmpty(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    final url = _buildUri(path, query: query);
    return http.post(url, headers: await _headers(json: false, auth: auth)).timeout(_timeout);
  }

  // ✅ PUT JSON
  Future<http.Response> put(
    String path,
    Object body, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    final url = _buildUri(path, query: query);
    return http
        .put(url, headers: await _headers(auth: auth), body: jsonEncode(body))
        .timeout(_timeout);
  }

  // ✅ PUT bez body
  Future<http.Response> putEmpty(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    final url = _buildUri(path, query: query);
    return http.put(url, headers: await _headers(json: false, auth: auth)).timeout(_timeout);
  }

  // ✅ NOVO: DELETE bez body (treba za favorites remove)
  Future<http.Response> deleteEmpty(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    final url = _buildUri(path, query: query);
    return http.delete(url, headers: await _headers(json: false, auth: auth)).timeout(_timeout);
  }

  // ✅ OVO TI TREBA ADMINU za multipart upload
  Future<Map<String, String>> multipartHeaders() async {
    final token = await _storage.getToken();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
