namespace RentLoop.API.Services.PayPal
{
    public class PayPalSettings
    {
        public string Mode { get; set; } = "Sandbox";
        public string ClientId { get; set; } = "";
        public string Secret { get; set; } = "";
        public string Currency { get; set; } = "EUR";
        public string ReturnUrl { get; set; } = "";
        public string CancelUrl { get; set; } = "";

        public string BaseUrl =>
            Mode.Equals("Live", StringComparison.OrdinalIgnoreCase)
                ? "https://api-m.paypal.com"
                : "https://api-m.sandbox.paypal.com";
    }
}
