namespace RentLoop.API.Models
{
    public class Payment
    {
        public int Id { get; set; }

        public int UserId { get; set; }
        public User? User { get; set; }

        public int ReservationId { get; set; }
        public Reservation? Reservation { get; set; }

        public string Provider { get; set; } = "PayPal";
        public string ProviderOrderId { get; set; } = string.Empty;

        public decimal Amount { get; set; }
        public string Currency { get; set; } = "EUR";

        public string Status { get; set; } = "CREATED"; // CREATED/CAPTURED/FAILED
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? CapturedAt { get; set; }
    }
}
