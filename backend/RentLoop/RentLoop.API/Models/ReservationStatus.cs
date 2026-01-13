namespace RentLoop.API.Models
{
    public class ReservationStatus
    {
        public int Id { get; set; } // 1 Pending, 2 Approved, 3 Rejected, 4 Cancelled
        public string Name { get; set; } = string.Empty;

        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
    }
}
