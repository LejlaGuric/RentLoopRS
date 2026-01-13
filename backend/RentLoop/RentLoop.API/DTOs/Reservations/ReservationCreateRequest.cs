namespace RentLoop.API.DTOs.Reservations
{
    public class ReservationCreateRequest
    {
        public int ListingId { get; set; }

        public DateTime CheckIn { get; set; }
        public DateTime CheckOut { get; set; }

        public int Guests { get; set; }
        public string? Note { get; set; }
    }
}
