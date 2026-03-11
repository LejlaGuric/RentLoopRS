using System.ComponentModel.DataAnnotations;

namespace RentLoop.API.DTOs.Auth
{
    public class AdminCreateUserRequest
    {
        [Required]
        [MaxLength(50)]
        public string Username { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        [RegularExpression(
            @"^[^\s@]+@[^\s@]+\.[^\s@]+$",
            ErrorMessage = "Email format is not valid.")]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string Password { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string LastName { get; set; } = string.Empty;

        [MaxLength(200)]
        public string Address { get; set; } = string.Empty;

        [MaxLength(30)]
        [RegularExpression(
            @"^$|^(\+?\d{8,15})$",
            ErrorMessage = "Phone format is not valid.")]
        public string Phone { get; set; } = string.Empty;

        // default client
        [Required]
        [Range(1, 2, ErrorMessage = "Role must be 1 (Admin) or 2 (Client).")]
        public int Role { get; set; } = 2;
    }
}