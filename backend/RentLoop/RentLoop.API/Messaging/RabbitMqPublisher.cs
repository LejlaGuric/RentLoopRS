using RabbitMQ.Client;
using System.Text;
using System.Text.Json;

namespace RentLoop.API.Messaging;

public class RabbitMqPublisher : IDisposable
{
    private readonly IConnection _connection;
    private readonly IModel _channel;
    private bool _disposed;

    public RabbitMqPublisher(IConfiguration cfg)
    {
        var host = cfg["RabbitMQ:Host"] ?? "rabbitmq";
        var user = cfg["RabbitMQ:User"] ?? "guest";
        var pass = cfg["RabbitMQ:Pass"] ?? "guest";

        var factory = new ConnectionFactory
        {
            HostName = host,
            Port = 5672,
            UserName = user,
            Password = pass,
            DispatchConsumersAsync = true
        };

        _connection = factory.CreateConnection();
        _channel = _connection.CreateModel();

        // approve queue
        _channel.QueueDeclare(
            queue: "reservation.approved",
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: null
        );

        // reject queue
        _channel.QueueDeclare(
            queue: "reservation.rejected",
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: null
        );
    }

    public void PublishReservationApproved(object payload)
    {
        Publish("reservation.approved", payload);
    }

    public void PublishReservationRejected(object payload)
    {
        Publish("reservation.rejected", payload);
    }

    private void Publish(string queueName, object payload)
    {
        if (_disposed)
            throw new ObjectDisposedException(nameof(RabbitMqPublisher));

        var json = JsonSerializer.Serialize(payload);
        var body = Encoding.UTF8.GetBytes(json);

        var props = _channel.CreateBasicProperties();
        props.Persistent = true;

        _channel.BasicPublish(
            exchange: "",
            routingKey: queueName,
            basicProperties: props,
            body: body
        );
    }

    public void Dispose()
    {
        if (_disposed) return;

        try
        {
            if (_channel.IsOpen)
                _channel.Close();
        }
        catch
        {
        }

        try
        {
            if (_connection.IsOpen)
                _connection.Close();
        }
        catch
        {
        }

        _channel.Dispose();
        _connection.Dispose();

        _disposed = true;
    }
}