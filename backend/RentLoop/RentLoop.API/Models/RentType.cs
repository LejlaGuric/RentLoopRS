using System.ComponentModel.DataAnnotations;

namespace RentLoop.API.Models
{
    public class RentType
    {
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string Name { get; set; } = string.Empty;

        public ICollection<Listing> Properties { get; set; } = new List<Listing>();
    }
}