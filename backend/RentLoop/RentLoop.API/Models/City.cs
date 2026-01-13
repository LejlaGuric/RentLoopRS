

namespace RentLoop.API.Models
{
    public class City
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;

        public ICollection<Listing> Properties { get; set; } = new List<Listing>();

    }
}
