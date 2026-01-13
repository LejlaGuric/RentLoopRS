

namespace RentLoop.API.Models
{
    public class PropertyImage
    {
        public int Id { get; set; }

        public int PropertyId { get; set; }
        public Listing? Property { get; set; }

        public string Url { get; set; } = string.Empty; // putanja ili link
        public bool IsCover { get; set; } = false;
        public int SortOrder { get; set; } = 0;
    }
}
