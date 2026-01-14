namespace RentLoop.API.DTOs.Chat
{
    public class ChatMessageDto
    {
        public int Id { get; set; }
        public int ConversationId { get; set; }

        public int SenderUserId { get; set; }
        public string SenderName { get; set; } = string.Empty;

        public string Text { get; set; } = string.Empty;
        public DateTime SentAt { get; set; }

        public bool IsRead { get; set; }
        public bool IsMine { get; set; } // radi UI-a (mobile/admin)
    }
}
