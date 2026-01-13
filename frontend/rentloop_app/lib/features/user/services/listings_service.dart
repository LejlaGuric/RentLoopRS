import 'dart:convert';

import '../../../core/http/api_client.dart';
import '../models/listing_card.dart';
import '../models/listing_details.dart';

class ListingsService {
  final ApiClient _api = ApiClient();

  List<ListingCard> _parseCards(String body) {
    final list = jsonDecode(body) as List<dynamic>;
    return list
        .map((e) => ListingCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ListingCard>> getAll({
    int? cityId,
    int? rentTypeId,
    double? minPrice,
    double? maxPrice,
    int? rooms,
    int? guests,
    String? sort,
    String? q, // ✅ SEARCH PO NAZIVU
  }) async {
    final query = <String, dynamic>{
      'cityId': cityId,
      'rentTypeId': rentTypeId,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'rooms': rooms,
      'guests': guests,
      'sort': sort,
    };

    // ✅ dodaj q samo ako nije prazno
    final term = q?.trim();
    if (term != null && term.isNotEmpty) {
      query['q'] = term;
    }

    final res = await _api.get(
      '/api/listings',
      query: query,
      auth: false, // ✅ listings ti je public endpoint
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(res.body.isEmpty ? 'Greška (${res.statusCode})' : res.body);
    }

    return _parseCards(res.body);
  }

  Future<List<ListingCard>> getRecommended({int take = 15}) async {
    final res = await _api.get(
      '/api/listings/recommended?take=$take',
      auth: true,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(res.body.isEmpty ? 'Greška (${res.statusCode})' : res.body);
    }

    return _parseCards(res.body);
  }

  Future<ListingDetails> getById(int id) async {
    final res = await _api.get('/api/listings/$id', auth: false);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(res.body.isEmpty ? 'Greška (${res.statusCode})' : res.body);
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return ListingDetails.fromJson(map);
  }

  Future<void> logView(int listingId) async {
    // Ako nemaš endpoint, ne ruši app
    try {
      await _api.postEmpty('/api/listings/$listingId/view', auth: true);
    } catch (_) {}
  }
}
