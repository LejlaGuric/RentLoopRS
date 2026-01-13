class AdminReservationItem {
  final int id;
  final DateTime checkIn;
  final DateTime checkOut;
  final double totalPrice;
  final int statusId;
  final String status;
  final String user;
  final String listing;
  final DateTime createdAt;
  final int guests;
  final String? note;

  AdminReservationItem({
    required this.id,
    required this.checkIn,
    required this.checkOut,
    required this.totalPrice,
    required this.statusId,
    required this.status,
    required this.user,
    required this.listing,
    required this.createdAt,
    required this.guests,
    this.note,
  });

  factory AdminReservationItem.fromJson(Map<String, dynamic> json) {
    return AdminReservationItem(
      id: (json['id'] ?? 0) as int,
      checkIn: DateTime.parse(json['checkIn']),
      checkOut: DateTime.parse(json['checkOut']),
      totalPrice: _toDouble(json['totalPrice']),
      statusId: (json['statusId'] ?? 0) as int,
      status: (json['status'] ?? '') as String,
      user: (json['user'] ?? '') as String,
      listing: (json['listing'] ?? '') as String,
      createdAt: DateTime.parse(json['createdAt']),
      guests: (json['guests'] ?? 0) as int,
      note: json['note']?.toString(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
