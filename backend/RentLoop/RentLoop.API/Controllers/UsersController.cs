using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;
using System.Security.Claims;

namespace RentLoop.API.Controllers
{
    [ApiController]
    [Route("api/users")]
    [Authorize]
    public class UsersController : ControllerBase
    {
        private readonly ApplicationDbContext _db;

        public UsersController(ApplicationDbContext db)
        {
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

        [HttpGet("me")]
        public async Task<IActionResult> Me()
        {
            var userId = GetUserId();
            if (userId == 0)
                return Unauthorized();

            var user = await _db.Users
                .AsNoTracking()
                .Where(u => u.Id == userId)
                .Select(u => new
                {
                    u.Id,
                    u.Username,
                    u.Email,
                    u.FirstName,
                    u.LastName,
                    u.Phone,
                    u.Address,
                    u.Role,
                    u.IsActive
                })
                .FirstOrDefaultAsync();

            if (user == null)
                return NotFound("User not found.");

            if (!user.IsActive)
                return Forbid();

            return Ok(user);
        }

        public class UpdateMeRequest
        {
            public string? FirstName { get; set; }
            public string? LastName { get; set; }
            public string? Phone { get; set; }
            public string? Address { get; set; }
        }

        [HttpPut("me")]
        public async Task<IActionResult> UpdateMe([FromBody] UpdateMeRequest req)
        {
            var userId = GetUserId();
            if (userId == 0)
                return Unauthorized();

            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null)
                return NotFound("User not found.");

            if (!user.IsActive)
                return Forbid();

            if (req.FirstName != null)
                user.FirstName = req.FirstName.Trim();

            if (req.LastName != null)
                user.LastName = req.LastName.Trim();

            if (req.Phone != null)
                user.Phone = req.Phone.Trim();

            if (req.Address != null)
                user.Address = req.Address.Trim();

            await _db.SaveChangesAsync();

            return Ok(new
            {
                user.Id,
                user.Username,
                user.Email,
                user.FirstName,
                user.LastName,
                user.Phone,
                user.Address,
                user.Role,
                user.IsActive
            });
        }
    }
}