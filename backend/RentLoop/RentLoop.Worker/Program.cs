using DotNetEnv;
using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;
using RentLoop.Worker;

var envPath = Path.Combine(Directory.GetCurrentDirectory(), ".env");
if (File.Exists(envPath))
{
    Env.Load(envPath);
}

IHost host = Host.CreateDefaultBuilder(args)
    .ConfigureServices((context, services) =>
    {
        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseSqlServer(
                context.Configuration.GetConnectionString("DefaultConnection")
            ));

        services.AddHostedService<Worker>();
    })
    .Build();

await host.RunAsync();