using Microsoft.AspNetCore.Http;

namespace RentLoop.API.DTOs.Listing
{
    public class ListingCreateFormDataRequest
    {
        public string Name { get; set; } = "";
        public string? Description { get; set; }
        public string? Address { get; set; }

        public int CityId { get; set; }
        public int RentTypeId { get; set; }

        public decimal PricePerNight { get; set; }
        public int RoomsCount { get; set; }
        public int MaxGuests { get; set; }
        public decimal DistanceToCenterKm { get; set; }

        public bool HasWifi { get; set; }
        public bool HasAirConditioning { get; set; }
        public bool PetsAllowed { get; set; }

        // JSON string, npr: [1,2,3]
        public string? AmenityIds { get; set; }

        public int CoverIndex { get; set; } = 0;

        // fajlovi sa frontenda
        public List<IFormFile> Images { get; set; } = new();
    }
}
