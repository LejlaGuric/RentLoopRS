import 'dart:convert';
import '../../../core/http/api_client.dart';
import '../models/admin_reservation_item.dart';

class AdminReservationsService {
  final ApiClient _api = ApiClient();

  /// ADMIN — sve rezervacije (optional filter statusId)
  Future<List<AdminReservationItem>> getAll({int? statusId}) async {
    final path = statusId == null
        ? '/api/reservations/admin'
        : '/api/reservations/admin?statusId=$statusId';

    final res = await _api.get(path);

    if (res.statusCode != 200) {
      throw Exception(_extractError(res.body) ?? 'Greška pri učitavanju rezervacija.');
    }

    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => AdminReservationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// (opcionalno) Pending shortcut
  Future<List<AdminReservationItem>> getPending() => getAll(statusId: 1);

  Future<void> approve(int id) async {
    final res = await _api.put('/api/reservations/$id/approve', {});
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_extractError(res.body) ?? 'Ne mogu odobriti rezervaciju.');
    }
  }

  Future<void> reject(int id) async {
    final res = await _api.put('/api/reservations/$id/reject', {});
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_extractError(res.body) ?? 'Ne mogu odbiti rezervaciju.');
    }
  }

  String? _extractError(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map && j['message'] != null) return j['message'].toString();
      if (j is String) return j;
      return null;
    } catch (_) {
      return body.isNotEmpty ? body : null;
    }
  }
}
