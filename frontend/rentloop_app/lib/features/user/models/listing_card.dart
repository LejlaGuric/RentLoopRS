class ListingCard {
  final int id;
  final String name;
  final double pricePerNight;
  final String city;
  final String rentType;
  final int roomsCount;
  final int maxGuests;
  final double distanceToCenterKm;
  final String? coverUrl;
  final double avgRating;
  final int reviewsCount;

  const ListingCard({
    required this.id,
    required this.name,
    required this.pricePerNight,
    required this.city,
    required this.rentType,
    required this.roomsCount,
    required this.maxGuests,
    required this.distanceToCenterKm,
    required this.coverUrl,
    required this.avgRating,
    required this.reviewsCount,
  });

  factory ListingCard.fromJson(Map<String, dynamic> j) => ListingCard(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: (j['name'] ?? '').toString(),
        pricePerNight: (j['pricePerNight'] as num?)?.toDouble() ?? 0.0,
        city: (j['city'] ?? '').toString(),
        rentType: (j['rentType'] ?? '').toString(),
        roomsCount: (j['roomsCount'] as num?)?.toInt() ?? 0,
        maxGuests: (j['maxGuests'] as num?)?.toInt() ?? 0,
        distanceToCenterKm: (j['distanceToCenterKm'] as num?)?.toDouble() ?? 0.0,
        coverUrl: j['coverUrl']?.toString(),
        avgRating: (j['avgRating'] as num?)?.toDouble() ?? 0.0,
        reviewsCount: (j['reviewsCount'] as num?)?.toInt() ?? 0,
      );
}
