using System.ComponentModel.DataAnnotations;

namespace RentLoop.API.Models
{
    public class Reservation
    {
        public int Id { get; set; }

        public int UserId { get; set; }
        public User? User { get; set; }

        public int PropertyId { get; set; }
        public Listing? Property { get; set; }

        public DateTime CheckIn { get; set; }
        public DateTime CheckOut { get; set; }

        public int Guests { get; set; }
        public decimal TotalPrice { get; set; }

        public bool IsPaid { get; set; } = false;
        public DateTime? PaidAt { get; set; }

        public int StatusId { get; set; }
        public ReservationStatus? Status { get; set; }

        public int? ApprovedByAdminId { get; set; }
        public User? ApprovedByAdmin { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? DecisionAt { get; set; }

        [MaxLength(1000)]
        public string? Note { get; set; }

        [MaxLength(500)]
        public string? RejectReason { get; set; }

        public Review? Review { get; set; }
    }
}