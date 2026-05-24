import 'dart:convert';

import '../../../core/http/api_client.dart';
import '../models/listing_card.dart';

class FavoritesService {
  final ApiClient _api = ApiClient();

  // GET: /api/favorites  -> vraća listu favorita (sa Listing objektom)
  Future<List<ListingCard>> myFavorites() async {
    final res = await _api.get('/api/favorites', auth: true);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_readMessage(res.body));
    }

    final list = jsonDecode(res.body) as List<dynamic>;

    // backend vraća: { propertyId, createdAt, listing: { ... } }
    final items = <ListingCard>[];
    for (final x in list) {
      final map = x as Map<String, dynamic>;
      final listing = map['listing'] as Map<String, dynamic>?;
      if (listing != null) {
        items.add(ListingCard.fromJson(listing));
      }
    }
    return items;
  }

  // GET: /api/favorites/check/{listingId}
  Future<bool> isFavorite(int listingId) async {
    final res = await _api.get('/api/favorites/check/$listingId', auth: true);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_readMessage(res.body));
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return (map['isFavorite'] as bool?) ?? false;
  }

  // POST: /api/favorites/{listingId}
  Future<void> add(int listingId) async {
    final res = await _api.postEmpty('/api/favorites/$listingId', auth: true);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_readMessage(res.body));
    }
  }

  // DELETE: /api/favorites/{listingId}
  Future<void> remove(int listingId) async {
    final res = await _api.deleteEmpty('/api/favorites/$listingId', auth: true);

    if (res.statusCode < 200 || res.statusCode >= 300) {
     throw Exception(_readMessage(res.body));
    }
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
