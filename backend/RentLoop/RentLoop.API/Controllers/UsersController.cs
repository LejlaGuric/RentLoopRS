using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;
using System.Security.Claims;

namespace RentLoop.API.Controllers
{
    [ApiController]
    [Route("api/users")]
    [Authorize] // svaki ulogovan korisnik
    public class UsersController : ControllerBase
    {
        private readonly ApplicationDbContext _db;

        public UsersController(ApplicationDbContext db)
        {
            _db = db;
        }

        // helper: uzmi userId iz JWT-a
        private int GetUserId()
        {
            var raw =
                User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? User.FindFirstValue("sub");

            if (string.IsNullOrWhiteSpace(raw))
                throw new Exception("Invalid token: missing user id claim.");

            return int.Parse(raw);
        }

        // --------------------
        // GET: api/users/me
        // Pregled mog profila
        // --------------------
        [HttpGet("me")]
        public async Task<IActionResult> Me()
        {
            var userId = GetUserId();

            var user = await _db.Users
                .AsNoTracking()
                .Where(u => u.Id == userId)
                .Select(u => new
                {
                    u.Id,
                    u.Username,
                    u.Email, // READ-ONLY
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

        // DTO za update profila (BEZ EMAILA)
        public class UpdateMeRequest
        {
            public string? FirstName { get; set; }
            public string? LastName { get; set; }
            public string? Phone { get; set; }
            public string? Address { get; set; }
        }

        // --------------------
        // PUT: api/users/me
        // Edit mog profila
        // --------------------
        [HttpPut("me")]
        public async Task<IActionResult> UpdateMe([FromBody] UpdateMeRequest req)
        {
            var userId = GetUserId();

            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null)
                return NotFound("User not found.");

            if (!user.IsActive)
                return Forbid();

            // Update dozvoljenih polja
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
                user.Email, // i dalje se vraća, ali se ne mijenja
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
