using System.ComponentModel.DataAnnotations;

namespace RentLoop.API.DTOs.Chat
{
    public class SendMessageRequest
    {
        [Required]
        [MaxLength(2000)]
        public string Text { get; set; } = string.Empty;
    }
}