namespace RentLoop.API.DTOs.Auth
{
    public class AdminCreateUserRequest
    {
        public string Username { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;

        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;

        public string Address { get; set; } = string.Empty;
        public string Phone { get; set; } = string.Empty;

        // default client
        public int Role { get; set; } = 2; // 1=Admin, 2=Client
    }
}

