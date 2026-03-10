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

            var r = await _db.Reservations.FirstOrDefaultAsync(x => x.Id == req.ReservationId);
            if (r == null) return NotFound("Reservation not found.");
            if (r.UserId != userId) return Forbid();

            if (!IsApproved(r))
                return BadRequest("Reservation must be approved (StatusId = 2) before payment.");

            if (r.IsPaid)
                return BadRequest("Reservation already paid.");

            var alreadyCaptured = await _db.Payments.AnyAsync(p =>
                p.ReservationId == r.Id && p.Provider == "PayPal" && p.Status == "CAPTURED");

            if (alreadyCaptured)
                return BadRequest("Reservation already paid (CAPTURED payment exists).");

            var openPaymentExists = await _db.Payments.AnyAsync(p =>
                p.ReservationId == r.Id && p.Provider == "PayPal" &&
                (p.Status == "CREATED" || p.Status == "APPROVED" || p.Status == "PAYER_ACTION_REQUIRED"));

            if (openPaymentExists)
                return BadRequest("Already exists open PayPal payment for this reservation.");

            var amount = r.TotalPrice;
            var currency = "EUR";

            var (orderId, approveUrl) = await _pp.CreateOrder(amount, currency, $"reservation-{r.Id}");

            _db.Payments.Add(new Payment
            {
                UserId = userId,
                ReservationId = r.Id,
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
                    p.ReservationId == req.ReservationId &&
                    p.ProviderOrderId == req.OrderId);

            if (payment == null) return NotFound("Payment not found.");
            if (payment.UserId != userId) return Forbid();

            if (payment.Status == "CAPTURED")
                return Ok(new CapturePayPalResponse("ALREADY_CAPTURED"));

            var status = await _pp.CaptureOrder(req.OrderId);

            if (status == "COMPLETED")
            {
                payment.Status = "CAPTURED";
                payment.CapturedAt = DateTime.UtcNow;

                if (payment.Reservation != null)
                {
                    payment.Reservation.IsPaid = true;
                    payment.Reservation.PaidAt = DateTime.UtcNow;
                }

                await _db.SaveChangesAsync();
                return Ok(new CapturePayPalResponse("COMPLETED"));
            }

            payment.Status = "FAILED";
            await _db.SaveChangesAsync();
            return Ok(new CapturePayPalResponse(status));
        }

        [HttpPost("paypal/dev-force-paid")]
        public async Task<IActionResult> DevForcePaid([FromBody] DevPaidRequest req)
        {
            if (!_env.IsDevelopment())
                return NotFound();

            var userId = GetUserId();
            if (userId == 0)
                return Unauthorized();

            var r = await _db.Reservations.FirstOrDefaultAsync(x => x.Id == req.ReservationId);
            if (r == null) return NotFound("Reservation not found.");
            if (r.UserId != userId) return Forbid();

            if (!IsApproved(r))
                return BadRequest("Reservation must be approved (StatusId = 2).");

            if (r.IsPaid)
                return BadRequest("Reservation already paid.");

            r.IsPaid = true;
            r.PaidAt = DateTime.UtcNow;

            _db.Payments.Add(new Payment
            {
                UserId = userId,
                ReservationId = r.Id,
                Provider = "PayPal",
                ProviderOrderId = "DEV-FORCED",
                Amount = r.TotalPrice,
                Currency = "EUR",
                Status = "CAPTURED",
                CapturedAt = DateTime.UtcNow
            });

            await _db.SaveChangesAsync();
            return Ok(new { ok = true, message = "DEV: marked as paid" });
        }
    }
}