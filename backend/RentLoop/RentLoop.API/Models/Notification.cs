

namespace RentLoop.API.Models
{
    public class Notification
    {
        public int Id { get; set; }

        public int UserId { get; set; }
        public User? User { get; set; }

        public int TypeId { get; set; }
        public NotificationType? Type { get; set; }

        public string Title { get; set; } = string.Empty;
        public string Body { get; set; } = string.Empty;

        public bool IsRead { get; set; } = false;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public int? RelatedPropertyId { get; set; }
        public Listing? RelatedProperty { get; set; }

        public int? RelatedReservationId { get; set; }
        public Reservation? RelatedReservation { get; set; }
    }
}
