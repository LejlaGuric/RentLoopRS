namespace RentLoop.API.DTOs.Auth
{
    public class LoginResponseDto
    {
        public string AccessToken { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
        public LoginUserDto User { get; set; } = new();
    }
}