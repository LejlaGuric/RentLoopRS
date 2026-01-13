import 'dart:convert';

import '../../../core/http/api_client.dart';
import '../models/lookup_item.dart';

class LookupsService {
  final ApiClient _api = ApiClient();

  List<LookupItem> _parseList(String body) {
    final list = jsonDecode(body) as List<dynamic>;
    return list.map((e) => LookupItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<LookupItem>> getCities() async {
    final res = await _api.get('/api/lookups/cities', auth: false);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(res.body.isEmpty ? 'Greška (${res.statusCode})' : res.body);
    }
    return _parseList(res.body);
  }

  Future<List<LookupItem>> getRentTypes() async {
    final res = await _api.get('/api/lookups/rent-types', auth: false);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(res.body.isEmpty ? 'Greška (${res.statusCode})' : res.body);
    }
    return _parseList(res.body);
  }

  Future<List<LookupItem>> getAmenities() async {
    final res = await _api.get('/api/lookups/amenities', auth: false);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(res.body.isEmpty ? 'Greška (${res.statusCode})' : res.body);
    }
    return _parseList(res.body);
  }
}
