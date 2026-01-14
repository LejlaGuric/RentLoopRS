using Microsoft.VisualBasic;

namespace RentLoop.API.Models
{
    public class User
    {
        public int Id { get; set; }

        public string Username { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;

        // Za početak (minimalno). Kasnije možeš JWT/Identity.
        public string PasswordHash { get; set; } = string.Empty;

        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;

        public string Address { get; set; } = string.Empty;
        public string Phone { get; set; } = string.Empty;

        // 1=Admin, 2=Client (možeš i kao tabelu Roles kasnije)
        public int Role { get; set; } = 2;

        public bool IsActive { get; set; } = true;

        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
        public ICollection<Favorite> Favorites { get; set; } = new List<Favorite>();
        public ICollection<SearchHistory> Searches { get; set; } = new List<SearchHistory>();

        // Chat
        // Chat: razgovori gdje je user klijent
        public ICollection<Conversation> ClientConversations { get; set; } = new List<Conversation>();

        // Chat: razgovori gdje je user admin (dodijeljeni razgovori)
        public ICollection<Conversation> AdminConversations { get; set; } = new List<Conversation>();

        public ICollection<Message> SentMessages { get; set; } = new List<Message>();
        public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
        public ICollection<ListingView> ListingViews { get; set; } = new List<ListingView>();

    }
}
