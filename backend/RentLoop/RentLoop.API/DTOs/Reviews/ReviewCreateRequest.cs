using System.ComponentModel.DataAnnotations;

namespace RentLoop.API.DTOs.Reviews
{
    public class ReviewCreateRequest
    {
        public int ReservationId { get; set; }

        [Range(1, 5)]
        public int Rating { get; set; }

        [MaxLength(1000)]
        public string? Comment { get; set; }
    }
}