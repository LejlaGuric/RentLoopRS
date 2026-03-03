using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
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

        public class DevSetPasswordReq
        {
            public string Value { get; set; } = "";     // username ili email
            public string NewPassword { get; set; } = "";
        }

        // ✅ Postavi password u PBKDF2 formatu (salt.hash) - preporučeno da sve bude jedno
        [HttpPost("dev/set-password")]
        public async Task<IActionResult> DevSetPassword([FromBody] DevSetPasswordReq req)
        {
            var value = (req.Value ?? "").Trim();
            var newPass = (req.NewPassword ?? "").Trim();

            var user = await _db.Users.FirstOrDefaultAsync(u => u.Username == value || u.Email == value);
            if (user == null) return NotFound("User not found");

            user.PasswordHash = HashPasswordPbkdf2(newPass);
            await _db.SaveChangesAsync();

            return Ok(new
            {
                user.Username,
                user.Email,
                format = DetectHashFormat(user.PasswordHash),
                hashPrefix = user.PasswordHash.Substring(0, Math.Min(12, user.PasswordHash.Length)),
                hashLen = user.PasswordHash.Length
            });
        }

        // ✅ Samo info da vidiš da API gleda pravu bazu
        [HttpGet("dev/db")]
        public async Task<IActionResult> DevDb()
        {
            var dbName = await _db.Database.SqlQueryRaw<string>("SELECT DB_NAME() AS Value").FirstAsync();
            var server = await _db.Database.SqlQueryRaw<string>("SELECT @@SERVERNAME AS Value").FirstAsync();
            var users = await _db.Users.CountAsync();
            var admins = await _db.Users.CountAsync(u => u.Username == "admin" || u.Email == "admin@rentloop.com");

            return Ok(new { dbName, server, users, admins });
        }

        // =========================
        // REGISTER
        // =========================

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            request.Username = (request.Username ?? "").Trim();
            request.Email = (request.Email ?? "").Trim().ToLowerInvariant();

            if (string.IsNullOrWhiteSpace(request.Username)) return BadRequest("Username is required.");
            if (string.IsNullOrWhiteSpace(request.Email)) return BadRequest("Email is required.");
            if (string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 6)
                return BadRequest("Password must be at least 6 characters.");

            var usernameTaken = await _db.Users.AnyAsync(u => u.Username.ToLower() == request.Username.ToLower());
            if (usernameTaken) return BadRequest("Username already exists.");

            var emailTaken = await _db.Users.AnyAsync(u => u.Email.ToLower() == request.Email.ToLower());
            if (emailTaken) return BadRequest("Email already exists.");

            var user = new User
            {
                Username = request.Username,
                Email = request.Email,
                // ✅ koristimo PBKDF2 "salt.hash"
                PasswordHash = HashPasswordPbkdf2(request.Password),
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

        // =========================
        // CHANGE PASSWORD
        // =========================

        [Authorize]
        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.CurrentPassword))
                return BadRequest("CurrentPassword is required.");

            if (string.IsNullOrWhiteSpace(request.NewPassword) || request.NewPassword.Length < 6)
                return BadRequest("NewPassword must be at least 6 characters.");

            var rawId =
                User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? User.FindFirstValue(JwtRegisteredClaimNames.Sub);

            if (string.IsNullOrWhiteSpace(rawId) || !int.TryParse(rawId, out var userId))
                return Unauthorized("Invalid token.");

            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null) return Unauthorized("User not found.");
            if (!user.IsActive) return Unauthorized("User is inactive.");

            // ✅ radi i za AQAAAA... i za salt.hash
            var ok = VerifyPasswordAny(user, request.CurrentPassword, user.PasswordHash);
            if (!ok) return BadRequest("Current password is not correct.");

            // ✅ nakon promjene prebacujemo u PBKDF2 (da ubuduće sve bude jedno)
            user.PasswordHash = HashPasswordPbkdf2(request.NewPassword);
            await _db.SaveChangesAsync();

            return Ok(new { message = "Password changed successfully." });
        }

        // =========================
        // LOGIN
        // =========================

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

            // ✅ KLJUČ: verifikacija radi za OBA hash formata
            var passwordOk = VerifyPasswordAny(user, request.Password, user.PasswordHash);
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

        // =========================
        // JWT
        // =========================

        private string CreateJwtToken(User user)
        {
            var jwt = _config.GetSection("Jwt");
            var key = jwt["Key"]!;
            var issuer = jwt["Issuer"]!;
            var audience = jwt["Audience"]!;

            // ✅ FIX: ne smije pucati ako ExpiresMinutes nije postavljen (npr. u Dockeru)
            var expiresStr = jwt["ExpiresMinutes"];
            var expiresMinutes = int.TryParse(expiresStr, out var m) ? m : 60; // default 60 min

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

        // =========================
        // PASSWORD HELPERS (FIX)
        // =========================

        // PBKDF2 format: "base64Salt.base64Hash"
        private static string HashPasswordPbkdf2(string password)
        {
            byte[] salt = RandomNumberGenerator.GetBytes(16);
            using var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 100_000, HashAlgorithmName.SHA256);
            byte[] hash = pbkdf2.GetBytes(32);

            return $"{Convert.ToBase64String(salt)}.{Convert.ToBase64String(hash)}";
        }

        private static bool VerifyPasswordPbkdf2(string password, string passwordHash)
        {
            var parts = passwordHash.Split('.');
            if (parts.Length != 2) return false;

            var salt = Convert.FromBase64String(parts[0]);
            var expectedHash = Convert.FromBase64String(parts[1]);

            using var pbkdf2 = new Rfc2898DeriveBytes(password, salt, 100_000, HashAlgorithmName.SHA256);
            var actualHash = pbkdf2.GetBytes(32);

            return CryptographicOperations.FixedTimeEquals(actualHash, expectedHash);
        }

        // ✅ radi i za PBKDF2 i za Identity (AQAAAA...)
        private static bool VerifyPasswordAny(User user, string password, string storedHash)
        {
            if (string.IsNullOrWhiteSpace(storedHash)) return false;

            // PBKDF2: ima tačku
            if (storedHash.Contains('.'))
            {
                try { return VerifyPasswordPbkdf2(password, storedHash); }
                catch { return false; }
            }

            // Identity PasswordHasher: obično počinje sa AQAAAA...
            if (storedHash.StartsWith("AQAAAA", StringComparison.Ordinal))
            {
                try
                {
                    var hasher = new PasswordHasher<User>();
                    var res = hasher.VerifyHashedPassword(user, storedHash, password);
                    return res == PasswordVerificationResult.Success;
                }
                catch { return false; }
            }

            // Ako je nešto treće - fail
            return false;
        }

        private static string DetectHashFormat(string hash)
        {
            if (string.IsNullOrWhiteSpace(hash)) return "Empty";
            if (hash.Contains('.')) return "PBKDF2(salt.hash)";
            if (hash.StartsWith("AQAAAA")) return "Identity(AQAAAA...)";
            return "Unknown";
        }
    }
}