import 'dart:convert';

import '../../../core/http/api_client.dart';
import '../models/lookup_item.dart';

class AdminLookupsService {
  final ApiClient _api = ApiClient();

  Future<List<LookupItem>> getCities() async {
    final res = await _api.get('/api/lookups/cities', auth: true);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list
          .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(res.body.isNotEmpty ? res.body : 'Greška pri učitavanju gradova.');
  }

  Future<void> createCity(String name) async {
    final res = await _api.post(
      '/api/lookups/cities',
      {'name': name},
      auth: true,
    );

    if (res.statusCode >= 200 && res.statusCode < 300) return;

    throw Exception(res.body.isNotEmpty ? res.body : 'Greška pri dodavanju grada.');
  }

  Future<void> updateCity(int id, String name) async {
    final res = await _api.put(
      '/api/lookups/cities/$id',
      {'name': name},
      auth: true,
    );

    if (res.statusCode >= 200 && res.statusCode < 300) return;

    throw Exception(res.body.isNotEmpty ? res.body : 'Greška pri izmjeni grada.');
  }

  Future<void> deleteCity(int id) async {
    final res = await _api.deleteEmpty('/api/lookups/cities/$id', auth: true);

    if (res.statusCode >= 200 && res.statusCode < 300) return;

    throw Exception(res.body.isNotEmpty ? res.body : 'Greška pri brisanju grada.');
  }

  Future<List<LookupItem>> getRentTypes() async {
    final res = await _api.get('/api/lookups/rent-types', auth: true);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list
          .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(res.body.isNotEmpty ? res.body : 'Greška pri učitavanju tipova najma.');
  }

  Future<void> createRentType(String name) async {
    final res = await _api.post(
      '/api/lookups/rent-types',
      {'name': name},
      auth: true,
    );

    if (res.statusCode >= 200 && res.statusCode < 300) return;

    throw Exception(res.body.isNotEmpty ? res.body : 'Greška pri dodavanju tipa najma.');
  }

  Future<void> updateRentType(int id, String name) async {
    final res = await _api.put(
      '/api/lookups/rent-types/$id',
      {'name': name},
      auth: true,
    );

    if (res.statusCode >= 200 && res.statusCode < 300) return;

    throw Exception(res.body.isNotEmpty ? res.body : 'Greška pri izmjeni tipa najma.');
  }

  Future<void> deleteRentType(int id) async {
    final res = await _api.deleteEmpty('/api/lookups/rent-types/$id', auth: true);

    if (res.statusCode >= 200 && res.statusCode < 300) return;

    throw Exception(res.body.isNotEmpty ? res.body : 'Greška pri brisanju tipa najma.');
  }

  Future<List<LookupItem>> getAmenities() async {
    final res = await _api.get('/api/lookups/amenities', auth: true);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list
          .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(res.body.isNotEmpty ? res.body : 'Greška pri učitavanju amenities.');
  }

  Future<void> createAmenity(String name) async {
    final res = await _api.post(
      '/api/lookups/amenities',
      {'name': name},
      auth: true,
    );

    if (res.statusCode >= 200 && res.statusCode < 300) return;

    throw Exception(res.body.isNotEmpty ? res.body : 'Greška pri dodavanju amenity-ja.');
  }

  Future<void> updateAmenity(int id, String name) async {
    final res = await _api.put(
      '/api/lookups/amenities/$id',
      {'name': name},
      auth: true,
    );

    if (res.statusCode >= 200 && res.statusCode < 300) return;

    throw Exception(res.body.isNotEmpty ? res.body : 'Greška pri izmjeni amenity-ja.');
  }

  Future<void> deleteAmenity(int id) async {
    final res = await _api.deleteEmpty('/api/lookups/amenities/$id', auth: true);

    if (res.statusCode >= 200 && res.statusCode < 300) return;

    throw Exception(res.body.isNotEmpty ? res.body : 'Greška pri brisanju amenity-ja.');
  }
}