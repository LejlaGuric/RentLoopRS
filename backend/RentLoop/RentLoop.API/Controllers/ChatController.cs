using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentLoop.API.DTOs.Chat;
using RentLoop.API.Services;
using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;
using RentLoop.API.Helpers;

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

        private int GetUserId()
        {
            var id = User.FindFirstValue(ClaimTypes.NameIdentifier)
                     ?? User.FindFirstValue("sub");

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

            return role == RoleIds.Admin;
        }

        [HttpGet("my-conversation")]
        public async Task<ActionResult<object>> GetMyConversation()
        {
            var userId = GetUserId();
            if (userId == 0)
                return Unauthorized();

            var conv = await _chat.GetOrCreateConversationForUserAsync(userId);
            return Ok(new { conversationId = conv.Id });
        }

        [HttpGet("admin/conversations")]
        public async Task<ActionResult<List<ChatConversationDto>>> AdminConversations()
        {
            var userId = GetUserId();
            if (userId == 0)
                return Unauthorized();

            if (!await IsAdminAsync(userId))
                return Forbid();

            var list = await _chat.GetAdminConversationsAsync();
            return Ok(list);
        }

        [HttpGet("conversations/{conversationId:int}/messages")]
        public async Task<ActionResult<List<ChatMessageDto>>> GetMessages(int conversationId)
        {
            var userId = GetUserId();
            if (userId == 0)
                return Unauthorized();

            var isAdmin = await IsAdminAsync(userId);

            var conv = await _chat.EnsureCanAccessConversationAsync(userId, isAdmin, conversationId);
            if (conv == null)
                return NotFound("Conversation not found or access denied.");

            var msgs = await _chat.GetMessagesAsync(conversationId, userId);
            return Ok(msgs);
        }

        [HttpPost("conversations/{conversationId:int}/messages")]
        public async Task<ActionResult<ChatMessageDto>> SendMessage(int conversationId, [FromBody] SendMessageRequest req)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            if (req == null)
                return BadRequest("Request body is required.");

            var text = (req.Text ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(text))
                return BadRequest("Text is required.");

            var userId = GetUserId();
            if (userId == 0)
                return Unauthorized();

            var isAdmin = await IsAdminAsync(userId);

            var conv = await _chat.EnsureCanAccessConversationAsync(userId, isAdmin, conversationId);
            if (conv == null)
                return NotFound("Conversation not found or access denied.");

            var msg = await _chat.SendMessageAsync(conversationId, userId, text);
            return Ok(msg);
        }

        [HttpPost("conversations/{conversationId:int}/read")]
        public async Task<ActionResult> MarkRead(int conversationId)
        {
            var userId = GetUserId();
            if (userId == 0)
                return Unauthorized();

            var isAdmin = await IsAdminAsync(userId);

            var conv = await _chat.EnsureCanAccessConversationAsync(userId, isAdmin, conversationId);
            if (conv == null)
                return NotFound("Conversation not found or access denied.");

            await _chat.MarkAsReadAsync(conversationId, userId);
            return Ok();
        }
    }
}