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

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                // 1) CONNECT (ako već nije)
                if (_connection == null || !_connection.IsOpen || _channel == null || !_channel.IsOpen)
                {
                    CleanupRabbit();

                    Console.WriteLine("⏳ Connecting to RabbitMQ...");

                    var factory = new ConnectionFactory
                    {
                        HostName = host,
                        Port = 5672,
                        UserName = user,
                        Password = pass,
                        DispatchConsumersAsync = true,

                        AutomaticRecoveryEnabled = true,
                        TopologyRecoveryEnabled = true,
                        NetworkRecoveryInterval = TimeSpan.FromSeconds(5),
                    };

                    IConnection? conn = null;

                    for (var attempt = 1; attempt <= 30; attempt++)
                    {
                        try
                        {
                            Console.WriteLine($"⏳ Connecting to RabbitMQ ({host})... attempt {attempt}/30");
                            conn = factory.CreateConnection();
                            break;
                        }
                        catch (Exception ex)
                        {
                            Console.WriteLine($"❌ RabbitMQ connect failed: {ex.Message}");
                            await Task.Delay(TimeSpan.FromSeconds(3), stoppingToken);
                        }
                    }

                    if (conn == null)
                    {
                        Console.WriteLine("❌ RabbitMQ not reachable after retries. Worker will stop.");
                        return;
                    }

                    _connection = conn; ;

                    _connection.ConnectionShutdown += (_, e) =>
                        Console.WriteLine($"❌ Rabbit connection shutdown: {e.ReplyText}");

                    _channel = _connection.CreateModel();

                    _channel.ModelShutdown += (_, e) =>
                        Console.WriteLine($"❌ Rabbit channel shutdown: {e.ReplyText}");

                    // 2) DECLARE QUEUE
                    _channel.QueueDeclare(
                        queue: "reservation.approved",
                        durable: true,
                        exclusive: false,
                        autoDelete: false,
                        arguments: null
                    );

                    // 3) CONSUME
                    var consumer = new AsyncEventingBasicConsumer(_channel);

                    consumer.Received += async (model, ea) =>
                    {
                        Console.WriteLine("✅ Received handler START");

                        try
                        {
                            var json = Encoding.UTF8.GetString(ea.Body.ToArray());
                            Console.WriteLine("✅ JSON OK: " + json);

                            var data = JsonSerializer.Deserialize<ReservationApprovedMessage>(json);

                            if (data == null)
                            {
                                Console.WriteLine("⚠️ data is null");
                                _channel.BasicAck(ea.DeliveryTag, false);
                                return;
                            }

                            using var scope = _scopeFactory.CreateScope();
                            var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

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
                            await db.SaveChangesAsync(stoppingToken);

                            _channel.BasicAck(ea.DeliveryTag, false);
                            Console.WriteLine("✅ SAVE + ACK OK");
                        }
                        catch (Exception ex)
                        {
                            Console.WriteLine("❌ PROCESS FAILED: " + ex);

                            // vrati poruku nazad u queue da se pokuša opet
                            try { _channel.BasicNack(ea.DeliveryTag, false, true); } catch { /* ignore */ }
                        }
                    };

                    _channel.BasicConsume(
                        queue: "reservation.approved",
                        autoAck: false,
                        consumer: consumer
                    );

                    Console.WriteLine("✅ CONSUMING reservation.approved");
                }

                // drži service živ
                await Task.Delay(1000, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                // gašenje
                break;
            }
            catch (Exception ex)
            {
                Console.WriteLine("❌ Worker loop error: " + ex);
                CleanupRabbit();

                // malo sačekaj prije ponovnog pokušaja
                await Task.Delay(2000, stoppingToken);
            }
        }

        CleanupRabbit();
    }

    private void CleanupRabbit()
    {
        try { _channel?.Close(); } catch { }
        try { _channel?.Dispose(); } catch { }
        _channel = null;

        try { _connection?.Close(); } catch { }
        try { _connection?.Dispose(); } catch { }
        _connection = null;
    }

    public override void Dispose()
    {
        CleanupRabbit();
        base.Dispose();
    }
}

public class ReservationApprovedMessage
{
    public int ReservationId { get; set; }
    public int UserId { get; set; }
    public int PropertyId { get; set; }
}
