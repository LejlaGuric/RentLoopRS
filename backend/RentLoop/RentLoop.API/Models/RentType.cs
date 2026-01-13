

namespace RentLoop.API.Models
{
    public class RentType
    {
        public int Id { get; set; }  // 1 ShortTerm, 2 LongTerm
        public string Name { get; set; } = string.Empty;

        public ICollection<Listing> Properties { get; set; } = new List<Listing>();
    }
}
