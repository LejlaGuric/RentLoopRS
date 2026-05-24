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
using RentLoop.API.Helpers;

namespace RentLoop.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly ApplicationDbContext _db;
        private readonly IConfiguration _config;
        private readonly ILogger<AuthController> _logger;

        public AuthController(
            ApplicationDbContext db,
            IConfiguration config,
            ILogger<AuthController> logger)
        {
            _db = db;
            _config = config;
            _logger = logger;
        }

        // =========================
        // REGISTER
        // =========================

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            if (!ModelState.IsValid)
            {
                _logger.LogWarning("Register failed due to invalid model state.");
                return BadRequest(ModelState);
            }

            request.Username = (request.Username ?? "").Trim();
            request.Email = (request.Email ?? "").Trim().ToLowerInvariant();
            request.FirstName = (request.FirstName ?? "").Trim();
            request.LastName = (request.LastName ?? "").Trim();
            request.Address = (request.Address ?? "").Trim();
            request.Phone = (request.Phone ?? "").Trim();

            _logger.LogInformation(
                "Register attempt for username {Username} and email {Email}",
                request.Username,
                request.Email);

            if (string.IsNullOrWhiteSpace(request.Username))
            {
                _logger.LogWarning("Register failed because username was empty.");
                return BadRequest("Username is required.");
            }

            if (string.IsNullOrWhiteSpace(request.Email))
            {
                _logger.LogWarning("Register failed for username {Username} because email was empty.", request.Username);
                return BadRequest("Email is required.");
            }

            if (string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 6)
            {
                _logger.LogWarning("Register failed for username {Username} because password did not meet minimum length.", request.Username);
                return BadRequest("Password must be at least 6 characters.");
            }

            var usernameTaken = await _db.Users.AnyAsync(u => u.Username.ToLower() == request.Username.ToLower());
            if (usernameTaken)
            {
                _logger.LogWarning("Register failed because username {Username} already exists.", request.Username);
                return BadRequest("Username already exists.");
            }

            var emailTaken = await _db.Users.AnyAsync(u => u.Email.ToLower() == request.Email.ToLower());
            if (emailTaken)
            {
                _logger.LogWarning("Register failed because email {Email} already exists.", request.Email);
                return BadRequest("Email already exists.");
            }

            var user = new User
            {
                Username = request.Username,
                Email = request.Email,
                PasswordHash = HashPasswordPbkdf2(request.Password),
                FirstName = request.FirstName ?? "",
                LastName = request.LastName ?? "",
                Address = request.Address ?? "",
                Phone = request.Phone ?? "",
                Role = RoleIds.Client,
                IsActive = true
            };

            _db.Users.Add(user);
            await _db.SaveChangesAsync();

            _logger.LogInformation(
                "User registered successfully. UserId: {UserId}, Username: {Username}, Role: {Role}",
                user.Id,
                user.Username,
                user.Role);

            return Ok(new { message = "Registered successfully." });
        }

        // =========================
        // CHANGE PASSWORD
        // =========================

        [Authorize]
        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            if (!ModelState.IsValid)
            {
                _logger.LogWarning("ChangePassword failed due to invalid model state.");
                return BadRequest(ModelState);
            }

            if (string.IsNullOrWhiteSpace(request.CurrentPassword))
            {
                _logger.LogWarning("ChangePassword failed because CurrentPassword was empty.");
                return BadRequest("CurrentPassword is required.");
            }

            if (string.IsNullOrWhiteSpace(request.NewPassword) || request.NewPassword.Length < 6)
            {
                _logger.LogWarning("ChangePassword failed because NewPassword did not meet minimum length.");
                return BadRequest("NewPassword must be at least 6 characters.");
            }

            var rawId =
                User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? User.FindFirstValue(JwtRegisteredClaimNames.Sub);

            if (string.IsNullOrWhiteSpace(rawId) || !int.TryParse(rawId, out var userId))
            {
                _logger.LogWarning("ChangePassword failed because token did not contain a valid user id.");
                return Unauthorized("Invalid token.");
            }

            _logger.LogInformation("ChangePassword attempt for userId {UserId}.", userId);

            var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null)
            {
                _logger.LogWarning("ChangePassword failed because user {UserId} was not found.", userId);
                return Unauthorized("User not found.");
            }

            if (!user.IsActive)
            {
                _logger.LogWarning("ChangePassword failed because user {UserId} is inactive.", userId);
                return Unauthorized("User is inactive.");
            }

            var ok = VerifyPasswordAny(user, request.CurrentPassword, user.PasswordHash);
            if (!ok)
            {
                _logger.LogWarning("ChangePassword failed because current password was invalid for user {UserId}.", userId);
                return BadRequest("Current password is not correct.");
            }

            user.PasswordHash = HashPasswordPbkdf2(request.NewPassword);
            await _db.SaveChangesAsync();

            _logger.LogInformation("Password changed successfully for user {UserId}.", userId);

            return Ok(new { message = "Password changed successfully." });
        }

        // =========================
        // LOGIN
        // =========================

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            if (!ModelState.IsValid)
            {
                _logger.LogWarning("Login failed due to invalid model state.");
                return BadRequest(ModelState);
            }

            if (string.IsNullOrWhiteSpace(request.UsernameOrEmail))
            {
                _logger.LogWarning("Login failed because UsernameOrEmail was empty.");
                return BadRequest("UsernameOrEmail is required.");
            }

            if (string.IsNullOrWhiteSpace(request.Password))
            {
                _logger.LogWarning("Login failed because password was empty.");
                return BadRequest("Password is required.");
            }

            var uoe = request.UsernameOrEmail.Trim();
            var uoeLower = uoe.ToLowerInvariant();

            _logger.LogInformation("Login attempt for identifier {Identifier}.", uoe);

            var user = await _db.Users.FirstOrDefaultAsync(u =>
                u.Username == uoe || u.Email == uoe || u.Email.ToLower() == uoeLower);

            if (user == null)
            {
                _logger.LogWarning("Login failed because no user matched identifier {Identifier}.", uoe);
                return Unauthorized("Invalid credentials.");
            }

            if (!user.IsActive)
            {
                _logger.LogWarning("Login failed because user {UserId} is inactive.", user.Id);
                return Unauthorized("User is inactive.");
            }

            var passwordOk = VerifyPasswordAny(user, request.Password, user.PasswordHash);
            if (!passwordOk)
            {
                _logger.LogWarning("Login failed because password was invalid for user {UserId}.", user.Id);
                return Unauthorized("Invalid credentials.");
            }

            var accessToken = CreateJwtToken(user);
            var refreshToken = GenerateRefreshToken();

            user.RefreshToken = refreshToken;
            user.RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(7);

            await _db.SaveChangesAsync();

            _logger.LogInformation(
                "Login successful for user {UserId} with role {Role}.",
                user.Id,
                user.Role);

            return Ok(new LoginResponseDto
            {
                AccessToken = accessToken,
                RefreshToken = refreshToken,
                User = new LoginUserDto
                {
                    Id = user.Id,
                    Username = user.Username,
                    Email = user.Email,
                    FirstName = user.FirstName,
                    LastName = user.LastName,
                    Role = user.Role
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

            var expiresStr = jwt["ExpiresMinutes"];
            var expiresMinutes = int.TryParse(expiresStr, out var m) ? m : 60;

            var claims = new List<Claim>
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.UniqueName, user.Username),
                new Claim(ClaimTypes.Role, user.Role == RoleIds.Admin ? "Admin" : "Client"),
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

        private string GenerateRefreshToken()
        {
            var randomNumber = new byte[64];

            using var rng = RandomNumberGenerator.Create();
            rng.GetBytes(randomNumber);

            return Convert.ToBase64String(randomNumber);
        }

        // =========================
        // PASSWORD HELPERS
        // =========================

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

        private static bool VerifyPasswordAny(User user, string password, string storedHash)
        {
            if (string.IsNullOrWhiteSpace(storedHash))
                return false;

            if (storedHash.Contains('.'))
            {
                try
                {
                    return VerifyPasswordPbkdf2(password, storedHash);
                }
                catch
                {
                    return false;
                }
            }

            if (storedHash.StartsWith("AQAAAA", StringComparison.Ordinal))
            {
                try
                {
                    var hasher = new PasswordHasher<User>();
                    var res = hasher.VerifyHashedPassword(user, storedHash, password);
                    return res == PasswordVerificationResult.Success;
                }
                catch
                {
                    return false;
                }
            }

            return false;
        }
        [HttpPost("refresh-token")]
        public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.RefreshToken))
                return Unauthorized("Refresh token is required.");

            var user = await _db.Users.FirstOrDefaultAsync(u =>
                u.RefreshToken == request.RefreshToken);

            if (user == null)
                return Unauthorized("Invalid refresh token.");

            if (!user.IsActive)
                return Unauthorized("User is inactive.");

            if (user.RefreshTokenExpiryTime <= DateTime.UtcNow)
                return Unauthorized("Refresh token expired.");

            var newAccessToken = CreateJwtToken(user);
            var newRefreshToken = GenerateRefreshToken();

            user.RefreshToken = newRefreshToken;
            user.RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(7);

            await _db.SaveChangesAsync();

            return Ok(new
            {
                accessToken = newAccessToken,
                refreshToken = newRefreshToken
            });
        }
    }
}