class ListingDetails {
  final int id;
  final String name;
  final String description;
  final String address;

  final double pricePerNight;
  final int roomsCount;
  final int maxGuests;
  final double distanceToCenterKm;

  final bool hasWifi;
  final bool hasAirConditioning;
  final bool petsAllowed;

  final String city;
  final String rentType;

  final List<ListingImageItem> images;
  final List<String> selectedAmenities;

  const ListingDetails({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.pricePerNight,
    required this.roomsCount,
    required this.maxGuests,
    required this.distanceToCenterKm,
    required this.hasWifi,
    required this.hasAirConditioning,
    required this.petsAllowed,
    required this.city,
    required this.rentType,
    required this.images,
    required this.selectedAmenities,
  });

  factory ListingDetails.fromJson(Map<String, dynamic> j) {
    final imgs = (j['images'] as List<dynamic>?)
            ?.map((e) => ListingImageItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return ListingDetails(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      address: (j['address'] ?? '').toString(),
      pricePerNight: (j['pricePerNight'] as num?)?.toDouble() ?? 0.0,
      roomsCount: (j['roomsCount'] as num?)?.toInt() ?? 0,
      maxGuests: (j['maxGuests'] as num?)?.toInt() ?? 0,
      distanceToCenterKm: (j['distanceToCenterKm'] as num?)?.toDouble() ?? 0.0,
      hasWifi: (j['hasWifi'] as bool?) ?? false,
      hasAirConditioning: (j['hasAirConditioning'] as bool?) ?? false,
      petsAllowed: (j['petsAllowed'] as bool?) ?? false,
      city: (j['city'] ?? '').toString(),
      rentType: (j['rentType'] ?? '').toString(),
      images: imgs,
      selectedAmenities: (j['selectedAmenities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class ListingImageItem {
  final int id;
  final String url;
  final bool isCover;
  final int sortOrder;

  const ListingImageItem({
    required this.id,
    required this.url,
    required this.isCover,
    required this.sortOrder,
  });

  factory ListingImageItem.fromJson(Map<String, dynamic> j) => ListingImageItem(
        id: (j['id'] as num?)?.toInt() ?? 0,
        url: (j['url'] ?? '').toString(),
        isCover: (j['isCover'] as bool?) ?? false,
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
      );
}
