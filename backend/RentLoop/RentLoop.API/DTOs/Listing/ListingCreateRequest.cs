using System.ComponentModel.DataAnnotations;

namespace RentLoop.API.DTOs
{
    public class ListingCreateRequest
    {
        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = "";

        [Required]
        [MaxLength(1000)]
        public string Description { get; set; } = "";

        [Required]
        [MaxLength(200)]
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

        public List<string> ImageUrls { get; set; } = new();
        public int CoverIndex { get; set; } = 0;

        public List<int> AmenityIds { get; set; } = new();
    }
}