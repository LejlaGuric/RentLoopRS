using Microsoft.EntityFrameworkCore;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using RentLoop.API.Data;
using RentLoop.API.Models;
using System.Text;
using System.Text.Json;

namespace RentLoop.Worker;

public class Worker : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;

    private IConnection? _connection;
    private IModel? _channel;

    public Worker(IServiceScopeFactory scopeFactory)
    {
        _scopeFactory = scopeFactory;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var host = Environment.GetEnvironmentVariable("RabbitMQ__Host") ?? "rabbitmq";
        var user = Environment.GetEnvironmentVariable("RabbitMQ__User") ?? "guest";
        var pass = Environment.GetEnvironmentVariable("RabbitMQ__Pass") ?? "guest";

        // retry konekcije na RabbitMQ
        for (var i = 1; i <= 30 && !stoppingToken.IsCancellationRequested; i++)
        {
            try
            {
                var factory = new ConnectionFactory
                {
                    HostName = host,
                    UserName = user,
                    Password = pass
                };

                _connection = factory.CreateConnection();
                _channel = _connection.CreateModel();

                Console.WriteLine("✅ Connected to RabbitMQ");
                break;
            }
            catch
            {
                Console.WriteLine($"⏳ Waiting for RabbitMQ... ({i}/30)");
                await Task.Delay(1000, stoppingToken);
            }
        }

        if (_channel == null) return;

        _channel.QueueDeclare(
            queue: "reservation.approved",
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: null
        );

        var consumer = new EventingBasicConsumer(_channel);
        consumer.Received += async (model, ea) =>
        {
            Console.WriteLine("✅ Received handler START");

            try
            {
                var json = Encoding.UTF8.GetString(ea.Body.ToArray());
                Console.WriteLine("✅ JSON OK: " + json);

                var data = JsonSerializer.Deserialize<ReservationApprovedMessage>(json);
                Console.WriteLine("✅ DESERIALIZE OK");

                if (data == null)
                {
                    Console.WriteLine("⚠️ data is null");
                    _channel.BasicAck(ea.DeliveryTag, false);
                    return;
                }

                using var scope = _scopeFactory.CreateScope();
                Console.WriteLine("✅ SCOPE OK");

                var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                Console.WriteLine("✅ DB CONTEXT OK");

                var notification = new Notification
                {
                    UserId = data.UserId,
                    TypeId = 1,
                    Title = "Rezervacija odobrena",
                    Body = "Vaša rezervacija je odobrena.",
                    RelatedPropertyId = data.PropertyId,
                    RelatedReservationId = data.ReservationId,
                    CreatedAt = DateTime.UtcNow
                };

                db.Notifications.Add(notification);
                Console.WriteLine("✅ ADD OK");

                await db.SaveChangesAsync();
                Console.WriteLine("✅ SAVE OK");

                _channel.BasicAck(ea.DeliveryTag, false);
                Console.WriteLine("✅ ACK OK");
            }
            catch (Exception ex)
            {
                Console.WriteLine("❌ SAVE FAILED: " + ex.ToString());
                _channel.BasicNack(ea.DeliveryTag, false, true); // vrati poruku nazad
            }
        };



        _channel.BasicConsume(
            queue: "reservation.approved",
            autoAck: false,
            consumer: consumer
        );

        while (!stoppingToken.IsCancellationRequested)
            await Task.Delay(1000, stoppingToken);
    }

    public override void Dispose()
    {
        _channel?.Close();
        _connection?.Close();
        base.Dispose();
    }
}

public class ReservationApprovedMessage
{
    public int ReservationId { get; set; }
    public int UserId { get; set; }
    public int PropertyId { get; set; }
}
