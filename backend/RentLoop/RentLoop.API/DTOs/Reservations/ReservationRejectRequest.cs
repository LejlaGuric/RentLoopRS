using System.ComponentModel.DataAnnotations;

namespace RentLoop.API.DTOs.Reservations
{
    public class ReservationRejectRequest
    {
        [Required]
        [MaxLength(500)]
        public string Reason { get; set; } = string.Empty;
    }
}