using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;
using RentLoop.API.DTOs.Auth;
using RentLoop.API.Models;
using System.Security.Cryptography;

namespace RentLoop.API.Controllers
{
    [ApiController]
    [Route("api/admin/users")]
    [Authorize(Roles = "Admin")]
    public class AdminUsersController : ControllerBase
    {
        private readonly ApplicationDbContext _db;

        public AdminUsersController(ApplicationDbContext db)
        {
            _db = db;
        }

        // GET: api/admin/users
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var users = await _db.Users
                .AsNoTracking()
                .OrderByDescending(u => u.Id)
                .Select(u => new
                {
                    u.Id,
                    u.Username,
                    u.Email,
                    u.FirstName,
                    u.LastName,
                    u.Role,
                    RoleName = u.Role == 1 ? "Admin" : "Client",
                    u.IsActive,
                    u.Phone,
                    u.Address,
                })
                .ToListAsync();

            return Ok(users);
        }

        // POST: api/admin/users
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] AdminCreateUserRequest request)
        {
            request.Username = (request.Username ?? "").Trim();
            request.Email = (request.Email ?? "").Trim().ToLowerInvariant();

            if (string.IsNullOrWhiteSpace(request.Username)) return BadRequest("Username is required.");
            if (string.IsNullOrWhiteSpace(request.Email)) return BadRequest("Email is required.");
            if (string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 6)
                return BadRequest("Password must be at least 6 characters.");

            if (request.Role != 1 && request.Role != 2)
                return BadRequest("Role must be 1 (Admin) or 2 (Client).");

            var usernameTaken = await _db.Users.AnyAsync(u => u.Username.ToLower() == request.Username.ToLower());
            if (usernameTaken) return BadRequest("Username already exists.");

            var emailTaken = await _db.Users.AnyAsync(u => u.Email.ToLower() == request.Email.ToLower());
            if (emailTaken) return BadRequest("Email already exists.");

            var user = new User
            {
                Username = request.Username,
                Email = request.Email,
                PasswordHash = HashPassword(request.Password),
                FirstName = request.FirstName ?? "",
                LastName = request.LastName ?? "",
                Address = request.Address ?? "",
                Phone = request.Phone ?? "",
                Role = request.Role,
                IsActive = true
            };

            _db.Users.Add(user);
            await _db.SaveChangesAsync();

            return Created($"/api/admin/users/{user.Id}", new
            {
                message = "User created.",
                user = new
                {
                    user.Id,
                    user.Username,
                    user.Email,
                    user.FirstName,
                    user.LastName,
                    user.Role,
                    RoleName = user.Role == 1 ? "Admin" : "Client",
                    user.IsActive
                }
            });
        }

        // PUT: api/admin/users/{id}/deactivate
        [HttpPut("{id:int}/deactivate")]
        public async Task<IActionResult> Deactivate(int id)
        {
            var user = await _db.Users.FirstOrDefaultAsync(x => x.Id == id);
            if (user == null) return NotFound("User not found.");

            if (user.Role == 1) return BadRequest("Cannot deactivate admin via this endpoint.");

            user.IsActive = false;
            await _db.SaveChangesAsync();

            return Ok(new { message = "User deactivated." });
        }

        // OPTIONAL: PUT: api/admin/users/{id}/activate
        [HttpPut("{id:int}/activate")]
        public async Task<IActionResult> Activate(int id)
        {
            var user = await _db.Users.FirstOrDefaultAsync(x => x.Id == id);
            if (user == null) return NotFound("User not found.");

            user.IsActive = true;
            await _db.SaveChangesAsync();

            return Ok(new { message = "User activated." });
        }

        // Simple hash (PBKDF2). PasswordHash format: "base64Salt.base64Hash"
        private static string HashPassword(string password)
        {
            byte[] salt = RandomNumberGenerator.GetBytes(16);
            using var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 100_000, HashAlgorithmName.SHA256);
            byte[] hash = pbkdf2.GetBytes(32);

            return $"{Convert.ToBase64String(salt)}.{Convert.ToBase64String(hash)}";
        }
    }
}
