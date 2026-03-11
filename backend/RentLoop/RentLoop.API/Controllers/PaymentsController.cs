using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;
using RentLoop.API.Models;
using RentLoop.API.Services.PayPal;
using System.Security.Claims;

namespace RentLoop.API.Controllers
{
    [ApiController]
    [Route("api/payments")]
    [Authorize]
    public class PaymentsController : ControllerBase
    {
        private readonly ApplicationDbContext _db;
        private readonly PayPalService _pp;
        private readonly IWebHostEnvironment _env;

        public PaymentsController(ApplicationDbContext db, PayPalService pp, IWebHostEnvironment env)
        {
            _db = db;
            _pp = pp;
            _env = env;
        }

        private int GetUserId()
        {
            var raw = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");

            if (string.IsNullOrWhiteSpace(raw))
                return 0;

            if (!int.TryParse(raw, out var userId))
                return 0;

            return userId;
        }

        private static bool IsApproved(Reservation r) => r.StatusId == 2;

        public record CreatePayPalOrderRequest(int ReservationId);
        public record CreatePayPalOrderResponse(string OrderId, string ApproveUrl);

        public record CapturePayPalRequest(int ReservationId, string OrderId);
        public record CapturePayPalResponse(string Status);

        public record DevPaidRequest(int ReservationId);

        [HttpPost("paypal/create-order")]
        public async Task<ActionResult<CreatePayPalOrderResponse>> CreatePayPalOrder([FromBody] CreatePayPalOrderRequest req)
        {
            var userId = GetUserId();
            if (userId == 0)
                return Unauthorized();

            var reservation = await _db.Reservations.FirstOrDefaultAsync(x => x.Id == req.ReservationId);
            if (reservation == null)
                return NotFound("Reservation not found.");

            if (reservation.UserId != userId)
                return Forbid();

            if (!IsApproved(reservation))
                return BadRequest("Reservation must be approved before payment.");

            if (reservation.IsPaid)
                return BadRequest("Reservation already paid.");

            var amount = reservation.TotalPrice;
            var currency = "EUR";

            var (orderId, approveUrl) = await _pp.CreateOrder(amount, currency, $"reservation-{reservation.Id}");

            _db.Payments.Add(new Payment
            {
                UserId = userId,
                ReservationId = reservation.Id,
                Provider = "PayPal",
                ProviderOrderId = orderId,
                Amount = amount,
                Currency = currency,
                Status = "CREATED"
            });

            await _db.SaveChangesAsync();

            return Ok(new CreatePayPalOrderResponse(orderId, approveUrl));
        }

        [HttpPost("paypal/capture")]
        public async Task<ActionResult<CapturePayPalResponse>> CapturePayPal([FromBody] CapturePayPalRequest req)
        {
            var userId = GetUserId();
            if (userId == 0)
                return Unauthorized();

            var payment = await _db.Payments
                .Include(p => p.Reservation)
                .FirstOrDefaultAsync(p =>
                    p.Provider == "PayPal" &&
                    p.ProviderOrderId == req.OrderId &&
                    p.ReservationId == req.ReservationId);

            if (payment == null)
                return NotFound("Payment not found.");

            if (payment.Reservation == null)
                return BadRequest("Reservation not found for payment.");

            if (payment.Reservation.UserId != userId)
                return Forbid();

            if (payment.Status == "CAPTURED")
                return Ok(new CapturePayPalResponse("ALREADY_CAPTURED"));

            try
            {
                var status = await _pp.CaptureOrder(req.OrderId);

                if (status == "COMPLETED")
                {
                    payment.Status = "CAPTURED";
                    payment.CapturedAt = DateTime.UtcNow;

                    payment.Reservation.IsPaid = true;
                    payment.Reservation.PaidAt = DateTime.UtcNow;

                    await _db.SaveChangesAsync();
                    return Ok(new CapturePayPalResponse("COMPLETED"));
                }

                payment.Status = "FAILED";
                await _db.SaveChangesAsync();

                return Ok(new CapturePayPalResponse(status));
            }
            catch (Exception ex)
            {
                payment.Status = "FAILED";
                await _db.SaveChangesAsync();

                return BadRequest(new
                {
                    message = ex.Message
                });
            }
        }

        [AllowAnonymous]
        [HttpGet("paypal/return")]
        public IActionResult PayPalReturn([FromQuery] string? token)
        {
            if (string.IsNullOrEmpty(token))
                return Content("Missing PayPal token");

            var deepLink = $"rentloop://paypal-return?token={Uri.EscapeDataString(token)}";

            var html =
                "<html><head>" +
                "<meta http-equiv='refresh' content='0;url=" + deepLink + "' />" +
                "</head><body>" +
                "Returning to app..." +
                "</body></html>";

            return Content(html, "text/html");
        }

        [AllowAnonymous]
        [HttpGet("paypal/cancel")]
        public IActionResult PayPalCancel()
        {
            var deepLink = "rentloop://paypal-cancel";

            var html =
                "<html><head>" +
                "<meta http-equiv='refresh' content='0;url=" + deepLink + "' />" +
                "</head><body>" +
                "Payment cancelled." +
                "</body></html>";

            return Content(html, "text/html");
        }
    }
}