import 'dart:convert';
import '../../../core/http/api_client.dart';
import '../models/admin_stats.dart';

class AdminDashboardService {
  final ApiClient _api = ApiClient();

  Future<AdminStats> getStats() async {
    final res = await _api.get('/api/admin/dashboard');

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('Nemaš pristup (Admin only).');
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Greška (${res.statusCode}) pri učitavanju statistike.');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return AdminStats.fromJson(data);
  }
}
