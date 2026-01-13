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
    throw Exception(res.body.isNotEmpty ? res.body : 'Greška pri učitavanju gradova.');
  }

  Future<List<LookupItem>> getRentTypes() async {
    final res = await _api.get('/api/lookups/rent-types');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) => LookupItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(res.body.isNotEmpty ? res.body : 'Greška pri učitavanju tipova najma.');
  }

  Future<List<LookupItem>> getAmenities() async {
    final res = await _api.get('/api/lookups/amenities');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) => LookupItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(res.body.isNotEmpty ? res.body : 'Greška pri učitavanju amenities.');
  }
}
