namespace RentLoop.API.Models
{
    public class Listing
    {
        public int Id { get; set; }

        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty;

        public int CityId { get; set; }
        public City? City { get; set; }

        public int RentTypeId { get; set; }
        public RentType? RentType { get; set; }

        public decimal PricePerNight { get; set; }
        public int RoomsCount { get; set; }
        public int MaxGuests { get; set; }
        public decimal DistanceToCenterKm { get; set; }

        public bool HasWifi { get; set; }
        public bool HasAirConditioning { get; set; }
        public bool PetsAllowed { get; set; }

        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public ICollection<PropertyImage> Images { get; set; } = new List<PropertyImage>();
        public ICollection<PropertyAmenity> PropertyAmenities { get; set; } = new List<PropertyAmenity>();
        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
        public ICollection<PropertyAvailability> Availability { get; set; } = new List<PropertyAvailability>();
        public ICollection<Review> Reviews { get; set; } = new List<Review>();
        public ICollection<Favorite> Favorites { get; set; } = new List<Favorite>();
    }
}
