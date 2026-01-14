namespace RentLoop.API.DTOs.Payments
{
    public record CreatePayPalOrderRequest(int ReservationId);
    public record CreatePayPalOrderResponse(string OrderId, string ApproveUrl);

    public record CapturePayPalRequest(int ReservationId, string OrderId);
    public record CapturePayPalResponse(string Status);

    public record DevPaidRequest(int ReservationId);
}
