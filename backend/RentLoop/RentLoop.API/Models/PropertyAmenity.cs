

namespace RentLoop.API.Models
{
    public class PropertyAmenity
    {
        public int PropertyId { get; set; }
        public Listing? Property { get; set; }

        public int AmenityId { get; set; }
        public Amenity? Amenity { get; set; }
    }
}
