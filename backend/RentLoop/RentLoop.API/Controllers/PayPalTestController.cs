using Microsoft.AspNetCore.Mvc;
using RentLoop.API.Services.PayPal;

namespace RentLoop.API.Controllers
{
    [ApiController]
    [Route("api/paypal-test")]
    public class PayPalTestController : ControllerBase
    {
        private readonly PayPalService _pp;

        public PayPalTestController(PayPalService pp)
        {
            _pp = pp;
        }

        [HttpGet("token")]
        public async Task<IActionResult> GetToken()
        {
            var token = await _pp.GetAccessToken();
            return Ok(new { token = token.Substring(0, 20) + "..." });
        }

        [HttpGet("create-order")]
        public async Task<IActionResult> CreateOrder()
        {
            var (orderId, approveUrl) = await _pp.CreateOrder(
                amount: 10.00m,
                currency: "EUR",
                referenceId: "test-123"
            );

            return Ok(new { orderId, approveUrl });
        }


        public record CaptureDto(string OrderId);

        [HttpPost("capture")]
        public async Task<IActionResult> Capture([FromBody] CaptureDto dto)
        {
            var status = await _pp.CaptureOrder(dto.OrderId.Trim());
            return Ok(new { status });
        }


    }
}
