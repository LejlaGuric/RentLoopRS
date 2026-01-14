import 'dart:convert';
import '../../../core/http/api_client.dart';

class MyReservationDto {
  final int id;
  final int listingId;
  final String listingTitle;
  final DateTime? from;
  final DateTime? to;
  final int statusId;
  final String statusName;
  final double totalPrice;

  MyReservationDto({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.from,
    required this.to,
    required this.statusId,
    required this.statusName,
    required this.totalPrice,
  });

  static DateTime? _tryParseDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  factory MyReservationDto.fromJson(Map<String, dynamic> j) {
    // Backend ti vraća Listing = { id, name } (po tvojem controlleru)
    final listingObj = j['listing'];
    final listingNameFromObj =
        listingObj is Map<String, dynamic> ? (listingObj['name'] ?? '').toString() : '';

    // Backend ti vraća propertyId (a ti ovdje zoveš listingId)
    final listingIdFromObj =
        listingObj is Map<String, dynamic> ? _toInt(listingObj['id']) : 0;

    final listingId = _toInt(
      j['listingId'] ?? j['propertyId'] ?? j['listing']?['id'] ?? listingIdFromObj,
    );

    final listingTitle = (j['listingTitle'] ??
            j['listingName'] ??
            (j['listing'] is Map ? (j['listing']['name'] ?? j['listing']['title']) : null) ??
            listingNameFromObj ??
            '')
        .toString();

    final from = _tryParseDate(
      j['from'] ?? j['dateFrom'] ?? j['startDate'] ?? j['checkIn'],
    );

    final to = _tryParseDate(
      j['to'] ?? j['dateTo'] ?? j['endDate'] ?? j['checkOut'],
    );

    final statusId = _toInt(j['statusId'] ?? j['status'] ?? 0);
    final statusName = (j['statusName'] ?? j['status'] ?? '').toString();

    final totalPrice = _toDouble(j['totalPrice'] ?? j['price']);

    return MyReservationDto(
      id: _toInt(j['id']),
      listingId: listingId,
      listingTitle: listingTitle,
      from: from,
      to: to,
      statusId: statusId,
      statusName: statusName,
      totalPrice: totalPrice,
    );
  }
}

/// DTO za POST /api/reservations
class ReservationCreateRequest {
  final int listingId;
  final DateTime checkIn;
  final DateTime checkOut; // backend očekuje checkOut AFTER checkIn
  final int guests;
  final String? note;

  ReservationCreateRequest({
    required this.listingId,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'listingId': listingId,
        'checkIn': checkIn.toUtc().toIso8601String(),
        'checkOut': checkOut.toUtc().toIso8601String(),
        'guests': guests,
        'note': note,
      };
}

class ReservationsService {
  final ApiClient _api = ApiClient();

  Future<List<MyReservationDto>> myReservations() async {
    final res = await _api.get('/api/reservations/my', auth: true);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Ne mogu učitati rezervacije (${res.statusCode}): ${res.body}');
    }

    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => MyReservationDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Kreira rezervaciju (PENDING)
  /// POST /api/reservations
   Future<String> createReservation(ReservationCreateRequest req) async {
  final res = await _api.post(
    '/api/reservations',
    req.toJson(), // ✅ Map -> ApiClient će ga jsonEncode-ati
    auth: true,
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception(_readMessage(res.body) ??
        'Greška pri kreiranju rezervacije (${res.statusCode}): ${res.body}');
  }

  return _readMessage(res.body) ?? 'Rezervacija kreirana (čeka odobrenje).';
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
