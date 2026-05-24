import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/http/api_client.dart';
import '../models/admin_listing_details.dart';
import '../models/admin_listing_list_item.dart';
import '../models/admin_listing_review.dart';
import 'package:http_parser/http_parser.dart';

class AdminListingsService {
  final ApiClient _api = ApiClient();

  Future<List<AdminListingListItem>> getAll({
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _api.get(
      '/api/listings',
      query: {
        'page': page,
        'pageSize': pageSize,
      },
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final list = (decoded['items'] as List?) ?? [];

      return list
          .map((e) => AdminListingListItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(_readMessage(res.body));
  }

  Future<AdminListingDetails> getById(int id) async {
    final res = await _api.get('/api/listings/$id');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      return AdminListingDetails.fromJson(map);
    }

    throw Exception(_readMessage(res.body));
  }

  Future<List<AdminListingReview>> getReviewsForListing(int listingId) async {
    final res = await _api.get('/api/reviews/listing/$listingId');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list
          .map((e) => AdminListingReview.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(_readMessage(res.body));
  }

  Future<void> createListingMultipart({
    required String name,
    required String description,
    required String address,
    required int cityId,
    required int rentTypeId,
    required double pricePerNight,
    required int roomsCount,
    required int maxGuests,
    required double distanceToCenterKm,
    required bool hasWifi,
    required bool hasAirConditioning,
    required bool petsAllowed,
    required String amenityIds,
    required int coverIndex,
    required List<String> imagePaths,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/listings');
    final req = http.MultipartRequest('POST', uri);

    req.headers.addAll(await _api.multipartHeaders());

    req.fields['Name'] = name;
    req.fields['Description'] = description;
    req.fields['Address'] = address;

    req.fields['CityId'] = cityId.toString();
    req.fields['RentTypeId'] = rentTypeId.toString();

    req.fields['PricePerNight'] = pricePerNight.toString();
    req.fields['RoomsCount'] = roomsCount.toString();
    req.fields['MaxGuests'] = maxGuests.toString();
    req.fields['DistanceToCenterKm'] = distanceToCenterKm.toString();

    req.fields['HasWifi'] = hasWifi.toString();
    req.fields['HasAirConditioning'] = hasAirConditioning.toString();
    req.fields['PetsAllowed'] = petsAllowed.toString();

    req.fields['AmenityIds'] = amenityIds;
    req.fields['CoverIndex'] = coverIndex.toString();

    for (final p in imagePaths) {
  final file = File(p);
  if (!file.existsSync()) continue;

  final filename = p.split(Platform.pathSeparator).last;

  final extension = filename.split('.').last.toLowerCase();

  String mimeType;

  if (extension == 'jpg' || extension == 'jpeg') {
    mimeType = 'jpeg';
  } else if (extension == 'png') {
    mimeType = 'png';
  } else if (extension == 'webp') {
    mimeType = 'webp';
  } else {
    throw Exception(
      'Dozvoljene su samo JPG, PNG i WEBP slike.',
    );
  }

  req.files.add(
    await http.MultipartFile.fromPath(
      'images',
      file.path,
      filename: filename,
      contentType: MediaType('image', mimeType),
    ),
  );
}

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception(_readMessage(body));
    }
  }

  Future<void> updateListing({
    required int id,
    required String name,
    required String description,
    required String address,
    required int cityId,
    required int rentTypeId,
    required double pricePerNight,
    required int roomsCount,
    required int maxGuests,
    required double distanceToCenterKm,
    required bool hasWifi,
    required bool hasAirConditioning,
    required bool petsAllowed,
  }) async {
    final res = await _api.put(
      '/api/listings/$id',
      {
        'name': name,
        'description': description,
        'address': address,
        'cityId': cityId,
        'rentTypeId': rentTypeId,
        'pricePerNight': pricePerNight,
        'roomsCount': roomsCount,
        'maxGuests': maxGuests,
        'distanceToCenterKm': distanceToCenterKm,
        'hasWifi': hasWifi,
        'hasAirConditioning': hasAirConditioning,
        'petsAllowed': petsAllowed,
        'images': [],
      },
      auth: true,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(_readMessage(res.body));
    }
  }

  Future<void> deactivateListing(int id) async {
    final res = await _api.putEmpty(
      '/api/listings/$id/deactivate',
      auth: true,
    );

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