import 'dart:convert';
import '../../../core/http/api_client.dart';

class AvailabilityService {
  final ApiClient _api = ApiClient();

  Future<Set<DateTime>> getBookedDates({
    required int propertyId,
    DateTime? from,
    DateTime? to,
  }) async {
    final res = await _api.get(
      '/api/availability/$propertyId',
      query: {
        'from': from?.toIso8601String(),
        'to': to?.toIso8601String(),
      },
      auth: true,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Ne mogu učitati zauzete dane (${res.statusCode}).');
    }

    final list = jsonDecode(res.body) as List<dynamic>;
    final dates = list.map((e) => DateTime.parse(e as String).toLocal()).toList();

    // normalizuj na date-only
    return dates.map((d) => DateTime(d.year, d.month, d.day)).toSet();
  }
}
