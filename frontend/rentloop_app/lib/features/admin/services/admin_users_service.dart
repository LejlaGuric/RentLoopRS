import 'dart:convert';
import '../../../core/http/api_client.dart';
import '../models/admin_user.dart';

class AdminUsersService {
  final ApiClient _api = ApiClient();

  Future<List<AdminUser>> getAll() async {
    final res = await _api.get('/api/admin/users', auth: true);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) => AdminUser.fromJson(e as Map<String, dynamic>)).toList();
    }

    throw Exception(res.body.isNotEmpty ? res.body : 'Greška pri učitavanju korisnika.');
  }

  Future<void> create({
    required String username,
    required String email,
    required String password,
    required int role,
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
  }) async {
    final res = await _api.post(
      '/api/admin/users',
      {
        'username': username,
        'email': email,
        'password': password,
        'role': role,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'address': address,
      },
      auth: true,
    );

    if (res.statusCode >= 200 && res.statusCode < 300) return;

    throw Exception(res.body.isNotEmpty ? res.body : 'Greška pri kreiranju korisnika.');
  }

  Future<void> deactivate(int id) async {
    final res = await _api.putEmpty('/api/admin/users/$id/deactivate', auth: true);

    if (res.statusCode >= 200 && res.statusCode < 300) return;

    throw Exception(res.body.isNotEmpty ? res.body : 'Greška pri deaktivaciji korisnika.');
  }

  // ✅ OPTIONAL: ako si dodala backend endpoint /activate
  Future<void> activate(int id) async {
    final res = await _api.putEmpty('/api/admin/users/$id/activate', auth: true);

    if (res.statusCode >= 200 && res.statusCode < 300) return;

    throw Exception(res.body.isNotEmpty ? res.body : 'Greška pri aktivaciji korisnika.');
  }
}
