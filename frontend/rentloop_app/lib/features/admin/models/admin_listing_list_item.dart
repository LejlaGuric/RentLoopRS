class AdminListingListItem {
  final int id;
  final String name;
  final double pricePerNight;
  final String city;
  final String rentType;
  final int roomsCount;
  final int maxGuests;
  final double distanceToCenterKm;
  final bool hasWifi;
  final bool hasAirConditioning;
  final bool petsAllowed;
  final bool isActive;
  final String? coverUrl;
  final double avgRating;
  final int reviewsCount;

  const AdminListingListItem({
    required this.id,
    required this.name,
    required this.pricePerNight,
    required this.city,
    required this.rentType,
    required this.roomsCount,
    required this.maxGuests,
    required this.distanceToCenterKm,
    required this.hasWifi,
    required this.hasAirConditioning,
    required this.petsAllowed,
    required this.isActive,
    required this.coverUrl,
    required this.avgRating,
    required this.reviewsCount,
  });

  factory AdminListingListItem.fromJson(Map<String, dynamic> json) {
    return AdminListingListItem(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      pricePerNight: (json['pricePerNight'] as num).toDouble(),
      city: (json['city'] ?? '').toString(),
      rentType: (json['rentType'] ?? '').toString(),
      roomsCount: (json['roomsCount'] as num).toInt(),
      maxGuests: (json['maxGuests'] as num).toInt(),
      distanceToCenterKm: (json['distanceToCenterKm'] as num).toDouble(),
      hasWifi: (json['hasWifi'] as bool?) ?? false,
      hasAirConditioning: (json['hasAirConditioning'] as bool?) ?? false,
      petsAllowed: (json['petsAllowed'] as bool?) ?? false,
      isActive: (json['isActive'] as bool?) ?? false,
      coverUrl: json['coverUrl']?.toString(),
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0,
      reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
    );
  }
}
