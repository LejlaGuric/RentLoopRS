namespace RentLoop.API.Models
{
    public class Conversation
    {
        public int Id { get; set; }

        // klijent
        public int UserId { get; set; }
        public User? User { get; set; }

        // admin (može biti null dok se ne dodijeli)
        public int? AdminId { get; set; }
        public User? Admin { get; set; }

        public DateTime LastMessageAt { get; set; } = DateTime.UtcNow;

        public ICollection<Message> Messages { get; set; } = new List<Message>();
    }
}
