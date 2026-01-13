

namespace RentLoop.API.Models
{
    public class Review
    {
        public int Id { get; set; }

        public int ReservationId { get; set; }
        public Reservation? Reservation { get; set; }

        public int PropertyId { get; set; }
        public Listing? Property { get; set; }

        public int UserId { get; set; }
        public User? User { get; set; }

        public int Rating { get; set; } // 1-5
        public string? Comment { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
