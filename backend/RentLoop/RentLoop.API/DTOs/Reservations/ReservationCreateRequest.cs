using System.ComponentModel.DataAnnotations;

namespace RentLoop.API.DTOs.Reservations
{
    public class ReservationCreateRequest
    {
        public int ListingId { get; set; }

        public DateTime CheckIn { get; set; }
        public DateTime CheckOut { get; set; }

        public int Guests { get; set; }

        [MaxLength(1000)]
        public string? Note { get; set; }
    }
}