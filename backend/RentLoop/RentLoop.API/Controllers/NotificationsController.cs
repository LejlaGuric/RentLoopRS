using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;
using RentLoop.API.Models;
using System.Security.Claims;

namespace RentLoop.API.Controllers
{
    [ApiController]
    [Route("api/notifications")]
    [Authorize]
    public class NotificationsController : ControllerBase
    {
        private readonly ApplicationDbContext _db;

        public NotificationsController(ApplicationDbContext db)
        {
            _db = db;
        }

        private int GetUserId()
        {
            var raw =
                User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? User.FindFirstValue("sub");

            if (string.IsNullOrWhiteSpace(raw))
                return 0;

            if (!int.TryParse(raw, out var userId))
                return 0;

            return userId;
        }

        [HttpGet("mine")]
        public async Task<IActionResult> Mine(
            [FromQuery] bool unreadOnly = false,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 20;
            if (pageSize > 100) pageSize = 100;

            var userId = GetUserId();
            if (userId == 0)
                return Unauthorized();

            var q = _db.Notifications
                .AsNoTracking()
                .Where(n => n.UserId == userId);

            if (unreadOnly)
                q = q.Where(n => !n.IsRead);

            var total = await q.CountAsync();

            var items = await q
                .OrderByDescending(n => n.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(n => new
                {
                    n.Id,
                    n.UserId,
                    n.TypeId,
                    TypeName = n.Type != null ? n.Type.Name : null,
                    n.Title,
                    n.Body,
                    n.IsRead,
                    n.CreatedAt,
                    n.RelatedPropertyId,
                    n.RelatedReservationId
                })
                .ToListAsync();

            return Ok(new
            {
                page,
                pageSize,
                total,
                items
            });
        }

        [HttpGet("unread-count")]
        public async Task<IActionResult> UnreadCount()
        {
            var userId = GetUserId();
            if (userId == 0)
                return Unauthorized();

            var count = await _db.Notifications
                .AsNoTracking()
                .Where(n => n.UserId == userId && !n.IsRead)
                .CountAsync();

            return Ok(new { count });
        }

        [HttpPut("{id:int}/read")]
        public async Task<IActionResult> MarkRead(int id)
        {
            var userId = GetUserId();
            if (userId == 0)
                return Unauthorized();

            var n = await _db.Notifications
                .FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId);

            if (n == null)
                return NotFound();

            if (!n.IsRead)
            {
                n.IsRead = true;
                await _db.SaveChangesAsync();
            }

            return Ok(new { ok = true });
        }

        [HttpPut("read-all")]
        public async Task<IActionResult> MarkAllRead()
        {
            var userId = GetUserId();
            if (userId == 0)
                return Unauthorized();

            var list = await _db.Notifications
                .Where(n => n.UserId == userId && !n.IsRead)
                .ToListAsync();

            if (list.Count == 0)
                return Ok(new { updated = 0 });

            foreach (var n in list)
                n.IsRead = true;

            await _db.SaveChangesAsync();

            return Ok(new { updated = list.Count });
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> Delete(int id)
        {
            var userId = GetUserId();
            if (userId == 0)
                return Unauthorized();

            var n = await _db.Notifications
                .FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId);

            if (n == null)
                return NotFound();

            _db.Notifications.Remove(n);
            await _db.SaveChangesAsync();

            return Ok(new { ok = true });
        }
    }
}