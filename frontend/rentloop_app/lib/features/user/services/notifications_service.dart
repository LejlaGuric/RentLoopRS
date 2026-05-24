import 'dart:convert';
import '../../../core/http/api_client.dart';
import '../models/notification_item.dart';

class NotificationsService {
  final ApiClient _api = ApiClient();

  List<NotificationItem> _parseList(String body) {
  final raw = jsonDecode(body) as Map<String, dynamic>;
  final list = (raw['items'] as List?) ?? [];

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
      throw Exception(_readMessage(res.body));
    }

    return _parseList(res.body);
  }

  Future<void> markAsRead(int id) async {
    final res = await _api.put(
      '/api/notifications/$id/read',
      {},
      auth: true,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception(_readMessage(res.body));    }
  }
  String _readMessage(String body) {
  try {
    final decoded = jsonDecode(body);

    if (decoded is Map && decoded['message'] is String) {
      return decoded['message'] as String;
    }
  } catch (_) {}

  return body.isNotEmpty ? body : 'Došlo je do greške.';
}
}