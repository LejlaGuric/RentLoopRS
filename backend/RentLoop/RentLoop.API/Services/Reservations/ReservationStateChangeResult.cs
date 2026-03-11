namespace RentLoop.API.Services.Reservations
{
    public class ReservationStateChangeResult
    {
        public bool Success { get; set; }

        public string Message { get; set; } = "";

        public static ReservationStateChangeResult Ok(string message = "Status updated successfully.")
        {
            return new ReservationStateChangeResult
            {
                Success = true,
                Message = message
            };
        }

        public static ReservationStateChangeResult Fail(string message)
        {
            return new ReservationStateChangeResult
            {
                Success = false,
                Message = message
            };
        }
    }
}