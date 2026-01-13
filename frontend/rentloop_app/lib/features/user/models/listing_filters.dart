class ListingFilters {
  int? cityId;
  int? rentTypeId;
  double? minPrice;
  double? maxPrice;
  int? rooms;
  int? guests;
  String sort;

  ListingFilters({
    this.cityId,
    this.rentTypeId,
    this.minPrice,
    this.maxPrice,
    this.rooms,
    this.guests,
    this.sort = 'newest',
  });

  ListingFilters copy() => ListingFilters(
        cityId: cityId,
        rentTypeId: rentTypeId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        rooms: rooms,
        guests: guests,
        sort: sort,
      );
}
