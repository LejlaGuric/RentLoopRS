

namespace RentLoop.API.Models
{
    public class PropertyAvailability
    {
        public int Id { get; set; }

        public int PropertyId { get; set; }
        public Listing? Property { get; set; }

        // jedan red = jedan datum
        public DateTime Date { get; set; }

        public bool IsBooked { get; set; }

        public int? ReservationId { get; set; }
        public Reservation? Reservation { get; set; }
    }
}
