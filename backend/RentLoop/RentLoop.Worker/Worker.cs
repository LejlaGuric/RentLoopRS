using Microsoft.EntityFrameworkCore;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using RentLoop.API.Data;
using RentLoop.API.Helpers;
using RentLoop.API.Models;
using System.Text;
using System.Text.Json;

namespace RentLoop.Worker;

public class Worker : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<Worker> _logger;

    private IConnection? _connection;
    private IModel? _channel;

    public Worker(IServiceScopeFactory scopeFactory, ILogger<Worker> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
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
                if (_connection == null || !_connection.IsOpen || _channel == null || !_channel.IsOpen)
                {
                    CleanupRabbit();

                    _logger.LogInformation("Connecting to RabbitMQ...");

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
                            _logger.LogInformation("Connecting to RabbitMQ ({Host}) attempt {Attempt}/30", host, attempt);
                            conn = factory.CreateConnection();
                            break;
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, "RabbitMQ connect failed on attempt {Attempt}/30", attempt);
                            await Task.Delay(TimeSpan.FromSeconds(3), stoppingToken);
                        }
                    }

                    if (conn == null)
                    {
                        _logger.LogError("RabbitMQ not reachable after retries. Worker will stop.");
                        return;
                    }

                    _connection = conn;

                    _connection.ConnectionShutdown += (_, e) =>
                        _logger.LogWarning("RabbitMQ connection shutdown: {Reason}", e.ReplyText);

                    _channel = _connection.CreateModel();

                    _channel.ModelShutdown += (_, e) =>
                        _logger.LogWarning("RabbitMQ channel shutdown: {Reason}", e.ReplyText);

                    _channel.QueueDeclare(
                        queue: "reservation.approved",
                        durable: true,
                        exclusive: false,
                        autoDelete: false,
                        arguments: null
                    );

                    _channel.QueueDeclare(
                        queue: "reservation.rejected",
                        durable: true,
                        exclusive: false,
                        autoDelete: false,
                        arguments: null
                    );

                    var approvedConsumer = new AsyncEventingBasicConsumer(_channel);

                    approvedConsumer.Received += async (model, ea) =>
                    {
                        try
                        {
                            var json = Encoding.UTF8.GetString(ea.Body.ToArray());
                            var data = JsonSerializer.Deserialize<ReservationApprovedMessage>(json);

                            if (data == null)
                            {
                                _channel.BasicAck(ea.DeliveryTag, false);
                                return;
                            }

                            using var scope = _scopeFactory.CreateScope();
                            var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

                            var exists = await db.Notifications.AnyAsync(n =>
                                n.UserId == data.UserId &&
                                n.TypeId == NotificationTypeIds.ReservationApproved &&
                                n.RelatedReservationId == data.ReservationId,
                                stoppingToken);

                            if (!exists)
                            {
                                var notification = new Notification
                                {
                                    UserId = data.UserId,
                                    TypeId = NotificationTypeIds.ReservationApproved,
                                    Title = "Rezervacija odobrena",
                                    Body = "Vaša rezervacija je odobrena.",
                                    RelatedPropertyId = data.PropertyId,
                                    RelatedReservationId = data.ReservationId,
                                    CreatedAt = DateTime.UtcNow
                                };

                                db.Notifications.Add(notification);
                                await db.SaveChangesAsync(stoppingToken);
                            }

                            _channel.BasicAck(ea.DeliveryTag, false);
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, "Error while processing reservation.approved message.");

                            try
                            {
                                _channel?.BasicNack(ea.DeliveryTag, false, false);
                            }
                            catch (Exception nackEx)
                            {
                                _logger.LogError(nackEx, "Failed to nack reservation.approved message.");
                            }
                        }
                    };

                    _channel.BasicConsume(
                        queue: "reservation.approved",
                        autoAck: false,
                        consumer: approvedConsumer
                    );

                    _logger.LogInformation("Consuming reservation.approved");

                    var rejectedConsumer = new AsyncEventingBasicConsumer(_channel);

                    rejectedConsumer.Received += async (model, ea) =>
                    {
                        try
                        {
                            var json = Encoding.UTF8.GetString(ea.Body.ToArray());
                            var data = JsonSerializer.Deserialize<ReservationRejectedMessage>(json);

                            if (data == null)
                            {
                                _channel.BasicAck(ea.DeliveryTag, false);
                                return;
                            }

                            using var scope = _scopeFactory.CreateScope();
                            var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

                            var exists = await db.Notifications.AnyAsync(n =>
                                n.UserId == data.UserId &&
                                n.TypeId == NotificationTypeIds.ReservationRejected &&
                                n.RelatedReservationId == data.ReservationId,
                                stoppingToken);

                            if (!exists)
                            {
                                var notification = new Notification
                                {
                                    UserId = data.UserId,
                                    TypeId = NotificationTypeIds.ReservationRejected,
                                    Title = "Rezervacija odbijena",
                                    Body = $"Vaša rezervacija je odbijena. Razlog: {data.RejectReason}",
                                    RelatedPropertyId = data.PropertyId,
                                    RelatedReservationId = data.ReservationId,
                                    CreatedAt = DateTime.UtcNow
                                };

                                db.Notifications.Add(notification);
                                await db.SaveChangesAsync(stoppingToken);
                            }

                            _channel.BasicAck(ea.DeliveryTag, false);
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, "Error while processing reservation.rejected message.");

                            try
                            {
                                _channel?.BasicNack(ea.DeliveryTag, false, false);
                            }
                            catch (Exception nackEx)
                            {
                                _logger.LogError(nackEx, "Failed to nack reservation.rejected message.");
                            }
                        }
                    };

                    _channel.BasicConsume(
                        queue: "reservation.rejected",
                        autoAck: false,
                        consumer: rejectedConsumer
                    );

                    _logger.LogInformation("Consuming reservation.rejected");
                }

                await Task.Delay(1000, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Worker loop error.");
                CleanupRabbit();
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

public class ReservationRejectedMessage
{
    public int ReservationId { get; set; }
    public int UserId { get; set; }
    public int PropertyId { get; set; }
    public string RejectReason { get; set; } = "";
}