namespace RentLoop.API.DTOs.Listing
{
    public class ListingCardDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = "";
        public decimal PricePerNight { get; set; }
        public string City { get; set; } = "";
        public string RentType { get; set; } = "";
        public int RoomsCount { get; set; }
        public int MaxGuests { get; set; }
        public decimal DistanceToCenterKm { get; set; }
        public string? CoverUrl { get; set; }
        public double AvgRating { get; set; }
        public int ReviewsCount { get; set; }
        public int Score { get; set; }
        public string? Reason { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}