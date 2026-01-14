using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;
using RentLoop.API.DTOs.Chat;
using RentLoop.API.Models;

namespace RentLoop.API.Services
{
    public class ChatService
    {
        private readonly ApplicationDbContext _db;

        public ChatService(ApplicationDbContext db)
        {
            _db = db;
        }

        // ✅ (1) User: uzmi ili kreiraj razgovor za trenutnog usera
        public async Task<Conversation> GetOrCreateConversationForUserAsync(int userId)
        {
            var conv = await _db.Conversations
                .FirstOrDefaultAsync(c => c.UserId == userId);

            if (conv != null) return conv;

            conv = new Conversation
            {
                UserId = userId,
                AdminId = null,
                LastMessageAt = DateTime.UtcNow
            };

            _db.Conversations.Add(conv);
            await _db.SaveChangesAsync();

            return conv;
        }

        // ✅ (2) Provjera prava pristupa konverzaciji
        // - Admin može sve
        // - User može samo svoje
        public async Task<Conversation> EnsureCanAccessConversationAsync(int currentUserId, bool isAdmin, int conversationId)
        {
            var conv = await _db.Conversations.FirstOrDefaultAsync(c => c.Id == conversationId);
            if (conv == null)
                throw new Exception("Conversation not found.");

            if (!isAdmin && conv.UserId != currentUserId)
                throw new Exception("Forbidden.");

            return conv;
        }

        // ✅ (3) Admin: lista razgovora (Inbox)
        public async Task<List<ChatConversationDto>> GetAdminConversationsAsync()
        {
            // Napomena: ako hoćeš da admin vidi samo dodijeljene, filtriraš po AdminId
            var list = await _db.Conversations
                .Include(c => c.User)
                .OrderByDescending(c => c.LastMessageAt)
                .ToListAsync();

            // Uzmi "zadnju poruku" za preview (MVP verzija: per conversation query)
            // Ako želiš optimizaciju, kasnije.
            var result = new List<ChatConversationDto>();

            foreach (var c in list)
            {
                var lastMsg = await _db.Messages
                    .Where(m => m.ConversationId == c.Id)
                    .OrderByDescending(m => m.SentAt)
                    .Select(m => new { m.Text })
                    .FirstOrDefaultAsync();

                result.Add(new ChatConversationDto
                {
                    Id = c.Id,
                    UserId = c.UserId,
                    UserName = c.User != null
                        ? $"{c.User.FirstName} {c.User.LastName}".Trim()
                        : $"User #{c.UserId}",
                    AdminId = c.AdminId,
                    LastMessageAt = c.LastMessageAt,
                    LastMessageText = lastMsg?.Text
                });
            }

            return result;
        }

        // ✅ (4) Poruke u razgovoru (zadnjih N)
        public async Task<List<ChatMessageDto>> GetMessagesAsync(int conversationId, int currentUserId)
        {
            // zadnjih 50, sortirano od starijih -> novijih za prikaz
            var msgs = await _db.Messages
                .Where(m => m.ConversationId == conversationId)
                .Include(m => m.SenderUser)
                .OrderByDescending(m => m.SentAt)
                .Take(50)
                .ToListAsync();

            msgs.Reverse();

            return msgs.Select(m => new ChatMessageDto
            {
                Id = m.Id,
                ConversationId = m.ConversationId,
                SenderUserId = m.SenderUserId,
                SenderName = m.SenderUser != null
                    ? $"{m.SenderUser.FirstName} {m.SenderUser.LastName}".Trim()
                    : $"User #{m.SenderUserId}",
                Text = m.Text,
                SentAt = m.SentAt,
                IsRead = m.IsRead,
                IsMine = m.SenderUserId == currentUserId
            }).ToList();
        }

        // ✅ (5) Slanje poruke (snimi u DB, update LastMessageAt)
        public async Task<ChatMessageDto> SendMessageAsync(int conversationId, int senderUserId, string text)
        {
            text = (text ?? "").Trim();
            if (string.IsNullOrWhiteSpace(text))
                throw new Exception("Text is required.");

            var conv = await _db.Conversations
                .FirstOrDefaultAsync(c => c.Id == conversationId);

            if (conv == null)
                throw new Exception("Conversation not found.");

            var msg = new Message
            {
                ConversationId = conversationId,
                SenderUserId = senderUserId,
                Text = text,
                SentAt = DateTime.UtcNow,
                IsRead = false
            };

            _db.Messages.Add(msg);

            conv.LastMessageAt = msg.SentAt;

            await _db.SaveChangesAsync();

            // učitaj sender za ime (MVP)
            var sender = await _db.Users.FirstOrDefaultAsync(u => u.Id == senderUserId);

            return new ChatMessageDto
            {
                Id = msg.Id,
                ConversationId = msg.ConversationId,
                SenderUserId = msg.SenderUserId,
                SenderName = sender != null
                    ? $"{sender.FirstName} {sender.LastName}".Trim()
                    : $"User #{senderUserId}",
                Text = msg.Text,
                SentAt = msg.SentAt,
                IsRead = msg.IsRead,
                IsMine = true
            };
        }

        // ✅ (6) Oznaci poruke kao procitane (najosnovnije)
        public async Task MarkAsReadAsync(int conversationId, int readerUserId)
        {
            // Markiramo sve poruke u tom razgovoru koje NISU od readera
            var toUpdate = await _db.Messages
                .Where(m => m.ConversationId == conversationId
                            && m.SenderUserId != readerUserId
                            && m.IsRead == false)
                .ToListAsync();

            foreach (var m in toUpdate)
                m.IsRead = true;

            await _db.SaveChangesAsync();
        }
    }
}
