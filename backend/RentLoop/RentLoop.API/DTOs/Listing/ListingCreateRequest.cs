namespace RentLoop.API.DTOs
{
    public class ListingCreateRequest
    {
        public string Name { get; set; } = "";
        public string Description { get; set; } = "";
        public string Address { get; set; } = "";

        public int CityId { get; set; }
        public int RentTypeId { get; set; }

        public decimal PricePerNight { get; set; }
        public int RoomsCount { get; set; }
        public int MaxGuests { get; set; }
        public decimal DistanceToCenterKm { get; set; }

        public bool HasWifi { get; set; }
        public bool HasAirConditioning { get; set; }
        public bool PetsAllowed { get; set; }
        public bool IsActive { get; set; } = true;

        // slike (URL-ovi) – FAZA 1
        public List<string> ImageUrls { get; set; } = new();
        public int CoverIndex { get; set; } = 0;

        // opcionalno amenities
        public List<int> AmenityIds { get; set; } = new();
    }
}
