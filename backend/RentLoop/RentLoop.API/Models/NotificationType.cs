namespace RentLoop.API.Models
{
    public class NotificationType
    {
        public int Id { get; set; } // npr. 1 PriceDrop, 2 ReservationApproved...
        public string Name { get; set; } = string.Empty;

        public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
    }
}
