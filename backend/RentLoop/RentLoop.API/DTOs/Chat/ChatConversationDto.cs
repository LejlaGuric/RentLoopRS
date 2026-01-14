namespace RentLoop.API.DTOs.Chat
{
    public class ChatConversationDto
    {
        public int Id { get; set; }
        public int UserId { get; set; }

        public string UserName { get; set; } = string.Empty;   // "Ime Prezime" ili Username/Email

        public int? AdminId { get; set; }

        public DateTime LastMessageAt { get; set; }

        public string? LastMessageText { get; set; }
    }
}
