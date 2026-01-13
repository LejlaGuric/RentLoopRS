using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using RentLoop.API.Data;
using RentLoop.API.DTOs.Auth;
using RentLoop.API.Models;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Authorization;

namespace RentLoop.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly ApplicationDbContext _db;
        private readonly IConfiguration _config;

        public AuthController(ApplicationDbContext db, IConfiguration config)
        {
            _db = db;
            _config = config;
        }

        // POST: api/auth/register
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            request.Username = (request.Username ?? "").Trim();
            request.Email = (request.Email ?? "").Trim().ToLowerInvariant();

            // basic validation
            if (string.IsNullOrWhiteSpace(request.Username)) return BadRequest("Username is required.");
            if (string.IsNullOrWhiteSpace(request.Email)) return BadRequest("Email is required.");
            if (string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 6)
                return BadRequest("Password must be at least 6 characters.");

            // unique checks (case-insensitive)
            var usernameTaken = await _db.Users.AnyAsync(u => u.Username.ToLower() == request.Username.ToLower());
            if (usernameTaken) return BadRequest("Username already exists.");

            var emailTaken = await _db.Users.AnyAsync(u => u.Email.ToLower() == request.Email.ToLower());
            if (emailTaken) return BadRequest("Email already exists.");

            // create user (Role=2 client)
            var user = new User
            {
                Username = request.Username,
                Email = request.Email,
                PasswordHash = HashPassword(request.Password),
                FirstName = request.FirstName ?? "",
                LastName = request.LastName ?? "",
                Address = request.Address ?? "",
                Phone = request.Phone ?? "",
                Role = 2,
                IsActive = true
            };

            _db.Users.Add(user);
            await _db.SaveChangesAsync();

            return Ok(new { message = "Registered successfully." });
        }

        // POST: api/auth/change-password
        [Authorize]
        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.CurrentPassword))
                return BadRequest("CurrentPassword is required.");

            if (string.IsNullOrWhiteSpace(request.NewPassword) || request.NewPassword.Length < 6)
                return BadRequest("NewPassword must be at least 6 characters.");

            // ✅ uzmi userId iz tokena (nameidentifier ili sub)
            var rawId =
                User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? User.FindFirstValue(JwtRegisteredClaimNames.Sub);

            if (string.IsNullOrWhiteSpace(rawId) || !int.TryParse(rawId, out var userId))
                return Unauthorized("Invalid token.");

            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null) return Unauthorized("User not found.");
            if (!user.IsActive) return Unauthorized("User is inactive.");

            // provjeri staru lozinku
            var ok = VerifyPassword(request.CurrentPassword, user.PasswordHash);
            if (!ok) return BadRequest("Current password is not correct.");

            // set nova lozinka
            user.PasswordHash = HashPassword(request.NewPassword);
            await _db.SaveChangesAsync();

            return Ok(new { message = "Password changed successfully." });
        }


        // POST: api/auth/login
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.UsernameOrEmail)) return BadRequest("UsernameOrEmail is required.");
            if (string.IsNullOrWhiteSpace(request.Password)) return BadRequest("Password is required.");

            var uoe = request.UsernameOrEmail.Trim();
            var uoeLower = uoe.ToLowerInvariant();

            var user = await _db.Users.FirstOrDefaultAsync(u =>
                u.Username == uoe || u.Email == uoe || u.Email.ToLower() == uoeLower);

            if (user == null) return Unauthorized("Invalid credentials.");
            if (!user.IsActive) return Unauthorized("User is inactive.");

            var passwordOk = VerifyPassword(request.Password, user.PasswordHash);
            if (!passwordOk) return Unauthorized("Invalid credentials.");

            var token = CreateJwtToken(user);

            return Ok(new
            {
                token,
                user = new
                {
                    user.Id,
                    user.Username,
                    user.Email,
                    user.FirstName,
                    user.LastName,
                    user.Role
                }
            });
        }

        private string CreateJwtToken(User user)
        {
            var jwt = _config.GetSection("Jwt");
            var key = jwt["Key"]!;
            var issuer = jwt["Issuer"]!;
            var audience = jwt["Audience"]!;
            var expiresMinutes = int.Parse(jwt["ExpiresMinutes"]!);

            var claims = new List<Claim>
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.UniqueName, user.Username),
                new Claim(ClaimTypes.Role, user.Role == 1 ? "Admin" : "Client"),
                new Claim("roleId", user.Role.ToString()),
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString())
            };

            var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key));
            var creds = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256);

            var token = new JwtSecurityToken(
                issuer: issuer,
                audience: audience,
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(expiresMinutes),
                signingCredentials: creds
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        // Simple hash (PBKDF2). PasswordHash format: "base64Salt.base64Hash"
        private static string HashPassword(string password)
        {
            byte[] salt = RandomNumberGenerator.GetBytes(16);
            using var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 100_000, HashAlgorithmName.SHA256);
            byte[] hash = pbkdf2.GetBytes(32);

            return $"{Convert.ToBase64String(salt)}.{Convert.ToBase64String(hash)}";
        }

        private static bool VerifyPassword(string password, string passwordHash)
        {
            var parts = passwordHash.Split('.');
            if (parts.Length != 2) return false;

            var salt = Convert.FromBase64String(parts[0]);
            var expectedHash = Convert.FromBase64String(parts[1]);

            using var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 100_000, HashAlgorithmName.SHA256);
            var actualHash = pbkdf2.GetBytes(32);

            return CryptographicOperations.FixedTimeEquals(actualHash, expectedHash);
        }
    }
}
