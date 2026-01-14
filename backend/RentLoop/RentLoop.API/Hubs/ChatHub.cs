using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;
using RentLoop.API.Services;
using System.Security.Claims;

namespace RentLoop.API.Hubs
{
    [Authorize]
    public class ChatHub : Hub
    {
        private readonly ChatService _chat;
        private readonly ApplicationDbContext _db;

        public ChatHub(ChatService chat, ApplicationDbContext db)
        {
            _chat = chat;
            _db = db;
        }

        private int GetUserId()
        {
            var raw =
                Context.User?.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? Context.User?.FindFirstValue("sub");

            if (string.IsNullOrWhiteSpace(raw))
                throw new HubException("Invalid token: missing userId");

            return int.Parse(raw);
        }

        private async Task<bool> IsAdminAsync(int userId)
        {
            var role = await _db.Users
                .Where(u => u.Id == userId)
                .Select(u => u.Role)
                .FirstOrDefaultAsync();

            return role == 1;
        }

        private static string GroupName(int conversationId) => $"conv-{conversationId}";

        // ✅ klijent/admin se "priključi" razgovoru
        public async Task JoinConversation(int conversationId)
        {
            var userId = GetUserId();
            var isAdmin = await IsAdminAsync(userId);

            await _chat.EnsureCanAccessConversationAsync(userId, isAdmin, conversationId);

            await Groups.AddToGroupAsync(Context.ConnectionId, GroupName(conversationId));
        }

        public async Task LeaveConversation(int conversationId)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, GroupName(conversationId));
        }

        // ✅ slanje poruke real-time + snimanje u bazu
        public async Task SendMessage(int conversationId, string text)
        {
            var userId = GetUserId();
            var isAdmin = await IsAdminAsync(userId);

            await _chat.EnsureCanAccessConversationAsync(userId, isAdmin, conversationId);

            var msgDto = await _chat.SendMessageAsync(conversationId, userId, text);

            // broadcast svima u group
            await Clients.Group(GroupName(conversationId))
                .SendAsync("NewMessage", msgDto);
        }

        // ✅ read receipts (najosnovnije)
        public async Task MarkRead(int conversationId)
        {
            var userId = GetUserId();
            var isAdmin = await IsAdminAsync(userId);

            await _chat.EnsureCanAccessConversationAsync(userId, isAdmin, conversationId);

            await _chat.MarkAsReadAsync(conversationId, userId);

            await Clients.Group(GroupName(conversationId))
                .SendAsync("MessagesRead", new { conversationId, readerUserId = userId });
        }
    }
}
