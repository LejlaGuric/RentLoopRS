using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentLoop.API.DTOs.Chat;
using RentLoop.API.Services;
using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;


namespace RentLoop.API.Controllers
{
    [ApiController]
    [Route("api/chat")]
    [Authorize]
    public class ChatController : ControllerBase
    {
        private readonly ChatService _chat;
        private readonly ApplicationDbContext _db;


        public ChatController(ChatService chat, ApplicationDbContext db)
        {
            _chat = chat;
            _db = db;
        }

        // helper: userId iz JWT-a (isti stil kao kod tebe prije)
        private int GetUserId()
        {
            var raw =
                User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? User.FindFirstValue("sub");

            if (string.IsNullOrWhiteSpace(raw))
                throw new Exception("Invalid token: missing userId");

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




        // ✅ USER: dobije svoj razgovor (kreira ako ne postoji)
        [HttpGet("my-conversation")]
        public async Task<ActionResult<object>> GetMyConversation()
        {
            var userId = GetUserId();
            var conv = await _chat.GetOrCreateConversationForUserAsync(userId);
            return Ok(new { conversationId = conv.Id });
        }

        // ✅ ADMIN: lista svih razgovora
        [HttpGet("admin/conversations")]
        public async Task<ActionResult<List<ChatConversationDto>>> AdminConversations()
        {
            var userId = GetUserId();
            if (!await IsAdminAsync(userId))
                return Forbid();

            var list = await _chat.GetAdminConversationsAsync();
            return Ok(list);
        }


        // ✅ USER/ADMIN: poruke u razgovoru
        [HttpGet("conversations/{conversationId:int}/messages")]
        public async Task<ActionResult<List<ChatMessageDto>>> GetMessages(int conversationId)
        {
            var userId = GetUserId();
            var isAdmin = await IsAdminAsync(userId);

            await _chat.EnsureCanAccessConversationAsync(userId, isAdmin, conversationId);

            var msgs = await _chat.GetMessagesAsync(conversationId, userId);
            return Ok(msgs);
        }


        // ✅ USER/ADMIN: pošalji poruku (REST fallback)
        [HttpPost("conversations/{conversationId:int}/messages")]
        public async Task<ActionResult<ChatMessageDto>> SendMessage(int conversationId, [FromBody] SendMessageRequest req)
        {
            var userId = GetUserId();
            var isAdmin = await IsAdminAsync(userId);

            await _chat.EnsureCanAccessConversationAsync(userId, isAdmin, conversationId);

            var msg = await _chat.SendMessageAsync(conversationId, userId, req.Text);
            return Ok(msg);
        }


        // ✅ USER/ADMIN: mark as read (najosnovnije)
        [HttpPost("conversations/{conversationId:int}/read")]
        public async Task<ActionResult> MarkRead(int conversationId)
        {
            var userId = GetUserId();
            var isAdmin = await IsAdminAsync(userId);

            await _chat.EnsureCanAccessConversationAsync(userId, isAdmin, conversationId);

            await _chat.MarkAsReadAsync(conversationId, userId);
            return Ok();
        }

    }
}
