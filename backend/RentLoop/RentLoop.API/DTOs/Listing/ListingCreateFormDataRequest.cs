using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace RentLoop.API.DTOs.Listing
{
    public class ListingCreateFormDataRequest
    {
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = "";

        [MaxLength(1000)]
        public string? Description { get; set; }

        [MaxLength(200)]
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

        public string? AmenityIds { get; set; }

        public int CoverIndex { get; set; } = 0;

        public List<IFormFile> Images { get; set; } = new();
    }
}