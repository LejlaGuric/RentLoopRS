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
            var id = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value
                     ?? Context.User?.FindFirst("sub")?.Value;

            if (string.IsNullOrWhiteSpace(id))
                return 0;

            if (!int.TryParse(id, out var userId))
                return 0;

            return userId;
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

        public async Task JoinConversation(int conversationId)
        {
            var userId = GetUserId();
            if (userId == 0)
                throw new HubException("Unauthorized.");

            var isAdmin = await IsAdminAsync(userId);

            await _chat.EnsureCanAccessConversationAsync(userId, isAdmin, conversationId);

            await Groups.AddToGroupAsync(Context.ConnectionId, GroupName(conversationId));
        }

        public async Task LeaveConversation(int conversationId)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, GroupName(conversationId));
        }

        public async Task SendMessage(int conversationId, string text)
        {
            var userId = GetUserId();
            if (userId == 0)
                throw new HubException("Unauthorized.");

            var isAdmin = await IsAdminAsync(userId);

            await _chat.EnsureCanAccessConversationAsync(userId, isAdmin, conversationId);

            var msgDto = await _chat.SendMessageAsync(conversationId, userId, text);

            await Clients.Group(GroupName(conversationId))
                .SendAsync("NewMessage", msgDto);
        }

        public async Task MarkRead(int conversationId)
        {
            var userId = GetUserId();
            if (userId == 0)
                throw new HubException("Unauthorized.");

            var isAdmin = await IsAdminAsync(userId);

            await _chat.EnsureCanAccessConversationAsync(userId, isAdmin, conversationId);

            await _chat.MarkAsReadAsync(conversationId, userId);

            await Clients.Group(GroupName(conversationId))
                .SendAsync("MessagesRead", new { conversationId, readerUserId = userId });
        }
    }
}