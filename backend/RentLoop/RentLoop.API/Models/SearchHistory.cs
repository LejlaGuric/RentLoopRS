namespace RentLoop.API.Models
{
    public class SearchHistory
    {
        public int Id { get; set; }

        public int UserId { get; set; }
        public User? User { get; set; }

        public int? CityId { get; set; }
        public City? City { get; set; }

        public int? RentTypeId { get; set; }
        public RentType? RentType { get; set; }

        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }

        public int? RoomsCount { get; set; }
        public int? Guests { get; set; }

        public string? Sort { get; set; }


        public DateTime SearchedAt { get; set; } = DateTime.UtcNow;
    }
}
