namespace RentLoop.API.DTOs.Common
{
    public class ApiErrorResponse
    {
        public string Message { get; set; } = "";
        public string? Code { get; set; }
    }
}