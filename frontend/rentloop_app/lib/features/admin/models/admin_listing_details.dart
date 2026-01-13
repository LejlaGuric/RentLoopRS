class AdminListingDetails {
  final int id;
  final String name;
  final String description;
  final String address;

  final double pricePerNight;
  final int roomsCount;
  final int maxGuests;
  final double distanceToCenterKm;

  final String city;
  final String rentType;

  final bool hasWifi;
  final bool hasAirConditioning;
  final bool petsAllowed;

  final bool isActive;

  final List<AdminListingImage> images;

  // ✅ NOVO: amenities
  final List<String> allAmenities;
  final List<String> selectedAmenities;

  AdminListingDetails({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.pricePerNight,
    required this.roomsCount,
    required this.maxGuests,
    required this.distanceToCenterKm,
    required this.city,
    required this.rentType,
    required this.hasWifi,
    required this.hasAirConditioning,
    required this.petsAllowed,
    required this.isActive,
    required this.images,
    required this.allAmenities,
    required this.selectedAmenities,
  });

  factory AdminListingDetails.fromJson(Map<String, dynamic> json) {
    final imagesJson = (json['Images'] ?? json['images'] ?? []) as List;

    // ✅ amenities (backend treba poslati AllAmenities i SelectedAmenities)
    final allA = (json['AllAmenities'] ?? json['allAmenities'] ?? []) as List;
    final selA = (json['SelectedAmenities'] ?? json['selectedAmenities'] ?? []) as List;

    return AdminListingDetails(
      id: (json['Id'] ?? json['id']) as int,
      name: (json['Name'] ?? json['name'] ?? '') as String,
      description: (json['Description'] ?? json['description'] ?? '') as String,
      address: (json['Address'] ?? json['address'] ?? '') as String,

      pricePerNight: _toDouble(json['PricePerNight'] ?? json['pricePerNight']),
      roomsCount: (json['RoomsCount'] ?? json['roomsCount'] ?? 0) as int,
      maxGuests: (json['MaxGuests'] ?? json['maxGuests'] ?? 0) as int,
      distanceToCenterKm: _toDouble(json['DistanceToCenterKm'] ?? json['distanceToCenterKm']),

      city: (json['City'] ?? json['city'] ?? '') as String,
      rentType: (json['RentType'] ?? json['rentType'] ?? '') as String,

      hasWifi: (json['HasWifi'] ?? json['hasWifi'] ?? false) as bool,
      hasAirConditioning: (json['HasAirConditioning'] ?? json['hasAirConditioning'] ?? false) as bool,
      petsAllowed: (json['PetsAllowed'] ?? json['petsAllowed'] ?? false) as bool,

      isActive: (json['IsActive'] ?? json['isActive'] ?? true) as bool,

      images: imagesJson
          .map((e) => AdminListingImage.fromJson(e as Map<String, dynamic>))
          .toList(),

      allAmenities: allA.map((e) => e.toString()).toList(),
      selectedAmenities: selA.map((e) => e.toString()).toList(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class AdminListingImage {
  final int id;
  final String url;
  final bool isCover;
  final int sortOrder;

  AdminListingImage({
    required this.id,
    required this.url,
    required this.isCover,
    required this.sortOrder,
  });

  factory AdminListingImage.fromJson(Map<String, dynamic> json) {
    return AdminListingImage(
      id: (json['Id'] ?? json['id']) as int,
      url: (json['Url'] ?? json['url'] ?? '') as String,
      isCover: (json['IsCover'] ?? json['isCover'] ?? false) as bool,
      sortOrder: (json['SortOrder'] ?? json['sortOrder'] ?? 0) as int,
    );
  }
}
