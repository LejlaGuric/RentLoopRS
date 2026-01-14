using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Options;

namespace RentLoop.API.Services.PayPal
{
    public class PayPalService
    {
        private readonly HttpClient _http;
        private readonly PayPalSettings _cfg;

        public PayPalService(HttpClient http, IOptions<PayPalSettings> cfg)
        {
            _http = http;
            _cfg = cfg.Value;
        }

        public async Task<string> GetAccessToken()
        {
            var url = $"{_cfg.BaseUrl}/v1/oauth2/token";
            using var req = new HttpRequestMessage(HttpMethod.Post, url);

            var basic = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{_cfg.ClientId}:{_cfg.Secret}"));
            req.Headers.Authorization = new AuthenticationHeaderValue("Basic", basic);
            req.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

            req.Content = new StringContent("grant_type=client_credentials", Encoding.UTF8, "application/x-www-form-urlencoded");

            var res = await _http.SendAsync(req);
            var body = await res.Content.ReadAsStringAsync();

            if (!res.IsSuccessStatusCode)
                throw new Exception($"PayPal token error: {(int)res.StatusCode} {res.StatusCode} - {body}");

            using var doc = JsonDocument.Parse(body);
            return doc.RootElement.GetProperty("access_token").GetString()!;
        }

        public async Task<(string orderId, string approveUrl)> CreateOrder(decimal amount, string currency, string referenceId)
        {
            var token = await GetAccessToken();
            var url = $"{_cfg.BaseUrl}/v2/checkout/orders";

            using var req = new HttpRequestMessage(HttpMethod.Post, url);
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            req.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

            var amountStr = amount.ToString("0.00", System.Globalization.CultureInfo.InvariantCulture);

            var payload = new
            {
                intent = "CAPTURE",
                purchase_units = new[]
                {
                    new
                    {
                        reference_id = referenceId,
                        amount = new { currency_code = currency, value = amountStr }
                    }
                },
                application_context = new
                {
                    user_action = "PAY_NOW",
                    landing_page = "LOGIN",
                    shipping_preference = "NO_SHIPPING",
                    locale = "en-US",
                    return_url = _cfg.ReturnUrl,
                    cancel_url = _cfg.CancelUrl
                }
            };

            req.Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

            var res = await _http.SendAsync(req);
            var body = await res.Content.ReadAsStringAsync();

            if (!res.IsSuccessStatusCode)
                throw new Exception($"PayPal create order error: {(int)res.StatusCode} {res.StatusCode} - {body}");

            using var doc = JsonDocument.Parse(body);
            var orderId = doc.RootElement.GetProperty("id").GetString()!;

            string? approveUrl = null;
            foreach (var link in doc.RootElement.GetProperty("links").EnumerateArray())
            {
                if (link.GetProperty("rel").GetString() == "approve")
                {
                    approveUrl = link.GetProperty("href").GetString();
                    break;
                }
            }

            if (approveUrl == null) throw new Exception("PayPal response missing approve link.");
            return (orderId, approveUrl);
        }

        public async Task<string> CaptureOrder(string orderId)
        {
            var token = await GetAccessToken();
            var url = $"{_cfg.BaseUrl}/v2/checkout/orders/{orderId}/capture";

            using var req = new HttpRequestMessage(HttpMethod.Post, url);
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
            req.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
            req.Content = new StringContent("", Encoding.UTF8, "application/json");

            var res = await _http.SendAsync(req);
            var body = await res.Content.ReadAsStringAsync();

            if (!res.IsSuccessStatusCode)
                throw new Exception($"PayPal capture error: {(int)res.StatusCode} {res.StatusCode} - {body}");

            using var doc = JsonDocument.Parse(body);
            return doc.RootElement.GetProperty("status").GetString()!; // COMPLETED kad uspije
        }
    }
}
