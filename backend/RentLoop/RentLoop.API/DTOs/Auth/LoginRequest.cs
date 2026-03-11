using System.ComponentModel.DataAnnotations;

namespace RentLoop.API.DTOs.Auth
{
    public class LoginRequest
    {
        [Required]
        [MaxLength(100)]
        public string UsernameOrEmail { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string Password { get; set; } = string.Empty;
    }
}