namespace RentLoop.API.Models
{
    public class ListingView
    {
        public int Id { get; set; }

        public int UserId { get; set; }
        public User? User { get; set; }

        public int ListingId { get; set; }
        public Listing? Listing { get; set; }

        public DateTime ViewedAt { get; set; } = DateTime.UtcNow;
    }
}
