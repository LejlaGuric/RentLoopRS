import 'dart:convert';
import '../../../core/http/api_client.dart';
import '../models/lookup_item.dart';

class LookupsService {
  final ApiClient _api = ApiClient();

  Future<List<LookupItem>> getCities() async {
    final res = await _api.get('/api/lookups/cities');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) => LookupItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(_readMessage(res.body));
  }

  Future<List<LookupItem>> getRentTypes() async {
    final res = await _api.get('/api/lookups/rent-types');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) => LookupItem.fromJson(e as Map<String, dynamic>)).toList();
    }
   throw Exception(_readMessage(res.body));
  }

  Future<List<LookupItem>> getAmenities() async {
    final res = await _api.get('/api/lookups/amenities');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) => LookupItem.fromJson(e as Map<String, dynamic>)).toList();
    }
   throw Exception(_readMessage(res.body));
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
