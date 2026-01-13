namespace RentLoop.API.DTOs.Reviews
{
    public class ReviewCreateRequest
    {
        public int ReservationId { get; set; }
        public int Rating { get; set; } // 1-5
        public string? Comment { get; set; }
    }
}
