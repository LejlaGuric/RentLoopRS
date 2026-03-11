using System.ComponentModel.DataAnnotations;

namespace RentLoop.API.DTOs.Auth
{
    public class ChangePasswordRequest
    {
        [Required]
        [MaxLength(100)]
        public string CurrentPassword { get; set; } = "";

        [Required]
        [MaxLength(100)]
        public string NewPassword { get; set; } = "";
    }
}