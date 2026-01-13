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

  factory MyReservationDto.fromJson(Map<String, dynamic> j) => MyReservationDto(
        id: (j['id'] ?? 0) as int,
        listingId: (j['listingId'] ?? 0) as int,
        listingTitle: (j['listingTitle'] ?? j['listingName'] ?? '').toString(),
        from: _tryParseDate(j['from'] ?? j['dateFrom'] ?? j['startDate']),
        to: _tryParseDate(j['to'] ?? j['dateTo'] ?? j['endDate']),
        statusId: (j['statusId'] ?? j['status'] ?? 0) as int,
        statusName: (j['statusName'] ?? '').toString(),
        totalPrice: _toDouble(j['totalPrice'] ?? j['price']),
      );
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
}
