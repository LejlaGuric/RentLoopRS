namespace RentLoop.API.Helpers
{
    public static class ReservationStatusNames
    {
        public static string GetName(int statusId)
        {
            return statusId switch
            {
                ReservationStatusIds.Pending => "Pending",
                ReservationStatusIds.Approved => "Approved",
                ReservationStatusIds.Rejected => "Rejected",
                ReservationStatusIds.Cancelled => "Cancelled",
                _ => "Unknown"
            };
        }
    }
}