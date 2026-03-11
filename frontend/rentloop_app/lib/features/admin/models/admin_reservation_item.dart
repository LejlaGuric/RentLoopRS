class AdminReservationItem {
  final int id;
  final DateTime checkIn;
  final DateTime checkOut;
  final double totalPrice;
  final int statusId;
  final String status;

  // USER
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;

  // USER HISTORY
  final int totalReservations;
  final int approvedReservations;
  final int cancelledReservations;
  final int rejectedReservations;

  // LISTING BASIC
  final String listing;

  // LISTING DETAILS
  final String description;
  final String address;
  final String city;
  final String rentType;
  final double pricePerNight;
  final int rooms;
  final int maxGuests;
  final bool wifi;
  final bool airConditioning;
  final bool petsAllowed;

  // AUDIT
  final String approvedByAdmin;
  final DateTime? decisionAt;
  final String rejectReason;

  final DateTime createdAt;
  final int guests;
  final String? note;

  final bool isPaid;
  final DateTime? paidAt;

  AdminReservationItem({
    required this.id,
    required this.checkIn,
    required this.checkOut,
    required this.totalPrice,
    required this.statusId,
    required this.status,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.totalReservations,
    required this.approvedReservations,
    required this.cancelledReservations,
    required this.rejectedReservations,
    required this.listing,
    required this.description,
    required this.address,
    required this.city,
    required this.rentType,
    required this.pricePerNight,
    required this.rooms,
    required this.maxGuests,
    required this.wifi,
    required this.airConditioning,
    required this.petsAllowed,
    required this.approvedByAdmin,
    required this.rejectReason,
    required this.createdAt,
    required this.guests,
    required this.isPaid,
    this.paidAt,
    this.decisionAt,
    this.note,
  });

  factory AdminReservationItem.fromJson(Map<String, dynamic> json) {
    final listing = json['listing'] ?? {};
    final user = json['user'] ?? {};

    return AdminReservationItem(
      id: (json['id'] ?? 0) as int,
      checkIn: DateTime.parse(json['checkIn']),
      checkOut: DateTime.parse(json['checkOut']).subtract(const Duration(days: 1)),
      totalPrice: _toDouble(json['totalPrice']),
      statusId: (json['statusId'] ?? 0) as int,
      status: (json['status'] ?? '') as String,

      username: (user['username'] ?? '') as String,
      firstName: (user['firstName'] ?? '') as String,
      lastName: (user['lastName'] ?? '') as String,
      email: (user['email'] ?? '') as String,
      phoneNumber: (user['phoneNumber'] ?? user['phone'] ?? '') as String,

      totalReservations: (user['totalReservations'] ?? 0) as int,
      approvedReservations: (user['approvedReservations'] ?? 0) as int,
      cancelledReservations: (user['cancelledReservations'] ?? 0) as int,
      rejectedReservations: (user['rejectedReservations'] ?? 0) as int,

      listing: (listing['name'] ?? '') as String,
      description: (listing['description'] ?? '') as String,
      address: (listing['address'] ?? '') as String,
      city: (listing['city'] ?? '') as String,
      rentType: (listing['rentType'] ?? '') as String,
      pricePerNight: _toDouble(listing['pricePerNight']),
      rooms: (listing['roomsCount'] ?? 0) as int,
      maxGuests: (listing['maxGuests'] ?? 0) as int,
      wifi: (listing['hasWifi'] ?? false) as bool,
      airConditioning: (listing['hasAirConditioning'] ?? false) as bool,
      petsAllowed: (listing['petsAllowed'] ?? false) as bool,

      approvedByAdmin: (json['approvedByAdmin'] ?? '') as String,
      rejectReason: (json['rejectReason'] ?? '') as String,
      decisionAt: json['decisionAt'] != null
          ? DateTime.parse(json['decisionAt'])
          : null,

      createdAt: DateTime.parse(json['createdAt']),
      guests: (json['guests'] ?? 0) as int,
      note: json['note']?.toString(),
      isPaid: (json['isPaid'] ?? false) == true,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}