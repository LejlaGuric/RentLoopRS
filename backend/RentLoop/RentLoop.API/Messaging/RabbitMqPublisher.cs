using RabbitMQ.Client;
using System.Text;
using System.Text.Json;

namespace RentLoop.API.Messaging;

public class RabbitMqPublisher
{
    private readonly string _host;
    private readonly string _user;
    private readonly string _pass;

    public RabbitMqPublisher(IConfiguration cfg)
    {
        _host = cfg["RabbitMQ:Host"] ?? "rabbitmq";
        _user = cfg["RabbitMQ:User"] ?? "guest";
        _pass = cfg["RabbitMQ:Pass"] ?? "guest";
    }

    public void PublishReservationApproved(object payload)
    {
        var factory = new ConnectionFactory
        {
            HostName = _host,     // ✅ koristi docker host
            Port = 5672,
            UserName = _user,
            Password = _pass,
            DispatchConsumersAsync = true
        };

        using var conn = factory.CreateConnection();
        using var ch = conn.CreateModel();

        ch.QueueDeclare(
            queue: "reservation.approved",
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: null
        );

        var json = JsonSerializer.Serialize(payload);
        var body = Encoding.UTF8.GetBytes(json);

        var props = ch.CreateBasicProperties();
        props.Persistent = true;

        ch.BasicPublish(
            exchange: "",
            routingKey: "reservation.approved",
            basicProperties: props,
            body: body
        );
    }
}