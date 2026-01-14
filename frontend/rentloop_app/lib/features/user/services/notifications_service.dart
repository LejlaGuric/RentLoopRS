import 'dart:convert';
import '../../../core/http/api_client.dart';
import '../models/notification_item.dart';

class NotificationsService {
  final ApiClient _api = ApiClient();

  List<NotificationItem> _parseList(String body) {
    final raw = jsonDecode(body);
    final list = raw is List ? raw : (raw['items'] as List<dynamic>? ?? []);
    return list
        .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<NotificationItem>> myNotifications() async {
    final res = await _api.get(
      '/api/notifications/mine',
      auth: true,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(res.body);
    }

    return _parseList(res.body);
  }

  Future<void> markAsRead(int id) async {
    // ✅ ApiClient.post očekuje (path, body, {auth})
    final res = await _api.post(
      '/api/notifications/$id/read',
      {},
      auth: true,
    );

    // ako endpoint još ne postoji, samo ignoriši
    if (res.statusCode < 200 || res.statusCode >= 300) return;
  }
}
