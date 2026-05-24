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
  final bool isPaid;
  final DateTime? paidAt;
  final String? rejectReason;
  final String? cancelReason;

 MyReservationDto({
  required this.id,
  required this.listingId,
  required this.listingTitle,
  required this.from,
  required this.to,
  required this.statusId,
  required this.statusName,
  required this.totalPrice,
  required this.isPaid,
  required this.paidAt,
  this.rejectReason,
  this.cancelReason,
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
  final listingObj = j['listing'];

  final listingId = _toInt(j['propertyId']);

  final listingTitle = listingObj is Map<String, dynamic>
      ? (listingObj['name'] ?? '').toString()
      : '';

  final from = _tryParseDate(j['checkIn']);
  final to = _tryParseDate(j['checkOut']);

  final statusId = _toInt(j['statusId']);
  final statusName = (j['status'] ?? '').toString();

  final totalPrice = _toDouble(j['totalPrice']);

  return MyReservationDto(
    id: _toInt(j['id']),
    listingId: listingId,
    listingTitle: listingTitle,
    from: from,
    to: to,
    statusId: statusId,
    statusName: statusName,
    totalPrice: totalPrice,
    isPaid: (j['isPaid'] ?? false) == true,
    paidAt: _tryParseDate(j['paidAt']),
    rejectReason: j['rejectReason']?.toString(),
    cancelReason: j['cancelReason']?.toString(),
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

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (decoded['items'] as List?) ?? [];

     return items
    .map((e) => MyReservationDto.fromJson(e as Map<String, dynamic>))
    .toList();
  }

 Future<void> cancelReservation(int id, String reason) async {
  final res = await _api.put(
    '/api/reservations/$id/cancel',
    {
      'reason': reason,
    },
    auth: true,
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception(
      res.body.isEmpty
          ? 'Greška pri otkazivanju rezervacije.'
          : res.body,
    );
  }
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
