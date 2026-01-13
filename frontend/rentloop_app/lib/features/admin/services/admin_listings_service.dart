import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/http/api_client.dart';
import '../models/admin_listing_details.dart';
import '../models/admin_listing_list_item.dart';

class AdminListingsService {
  final ApiClient _api = ApiClient();

  Future<List<AdminListingListItem>> getAll() async {
    final res = await _api.get('/api/listings');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) => AdminListingListItem.fromJson(e as Map<String, dynamic>)).toList();
    }

    throw Exception(res.body.isNotEmpty ? res.body : 'Greška pri učitavanju stanova.');
  }

  Future<AdminListingDetails> getById(int id) async {
    final res = await _api.get('/api/listings/$id');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      return AdminListingDetails.fromJson(map);
    }

    throw Exception(res.body.isNotEmpty ? res.body : 'Greška pri učitavanju detalja.');
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
      req.files.add(await http.MultipartFile.fromPath('Images', file.path, filename: filename));
    }

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception(body.isNotEmpty ? body : 'Greška pri dodavanju stana.');
    }
  }
}
