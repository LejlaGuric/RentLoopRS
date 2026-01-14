import 'dart:convert';
import '../../../core/http/api_client.dart';
import '../models/review_create_request.dart';

class ReviewsService {
  final ApiClient _api = ApiClient();

  Future<String> createReview(ReviewCreateRequest req) async {
    final res = await _api.post(
      '/api/reviews',
      req.toJson(), // ✅ ne jsonEncode (ApiClient već enkodira)
      auth: true,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_readMessage(res.body) ??
          'Greška pri slanju ocjene (${res.statusCode}): ${res.body}');
    }

    return _readMessage(res.body) ?? 'Ocjena sačuvana.';
  }

  String? _readMessage(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map && j['message'] is String) return j['message'] as String;
      if (j is String) return j;
    } catch (_) {}
    return null;
  }
}
