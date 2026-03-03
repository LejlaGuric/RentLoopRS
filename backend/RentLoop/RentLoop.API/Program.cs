using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Microsoft.OpenApi.Models;
using System.Security.Claims;
using RentLoop.API.Services.PayPal;
using RentLoop.API.Services;
using RentLoop.API.Hubs; // ✅ DODANO: da može MapHub<ChatHub>

var builder = WebApplication.CreateBuilder(args);

var jwtSection = builder.Configuration.GetSection("Jwt");
var jwtKey = jwtSection["Key"]!;
var jwtIssuer = jwtSection["Issuer"]!;
var jwtAudience = jwtSection["Audience"]!;

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Controllers
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSignalR();

builder.Services.Configure<PayPalSettings>(builder.Configuration.GetSection("PayPal"));
builder.Services.AddHttpClient();

builder.Services.AddHttpClient<PayPalService>();
builder.Services.AddScoped<ChatService>();

builder.Services.AddSingleton<RentLoop.API.Messaging.RabbitMqPublisher>();
Console.WriteLine("DB = " + builder.Configuration.GetConnectionString("DefaultConnection"));

// ✅ CORS mora biti OVDJE (prije Build)
builder.Services.AddCors(options =>
{
    options.AddPolicy("SpaCors", p => p
        .WithOrigins("http://localhost:4200", "https://localhost:4200", "http://localhost:5068")
        .AllowAnyHeader()
        .AllowAnyMethod()
        .AllowCredentials()
    );
});

// Swagger + JWT Authorize
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new() { Title = "RentLoop.API", Version = "v1" });

    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Unesi: Bearer {tvoj_token}"
    });

    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// Auth
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,

            ValidIssuer = jwtIssuer,
            ValidAudience = jwtAudience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),

            ClockSkew = TimeSpan.Zero,

            // ✅ OVO OSIGURAVA da [Authorize(Roles="Admin")] radi uvijek
            RoleClaimType = ClaimTypes.Role,
            NameClaimType = ClaimTypes.NameIdentifier
        };

        // ✅ DODANO: SignalR šalje token kao ?access_token=...
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken = context.Request.Query["access_token"];
                var path = context.HttpContext.Request.Path;

                if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs/chat"))
                {
                    context.Token = accessToken;
                }

                return Task.CompletedTask;
            }
        };
    });

builder.Services.AddAuthorization();

var app = builder.Build();

// ✅ Migracije + seed (Admin/Demo) pri startu
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

    // opcionalno: automatski primijeni migracije
    db.Database.Migrate();

    // seed usera sa pravim hashom (Admin123!, Demo123!)
    await DbSeeder.SeedAsync(db);
}


// Swagger

    app.UseSwagger();
    app.UseSwaggerUI();


// ✅ CORS middleware ide ovdje (poslije Build, prije Auth)
app.UseCors("SpaCors");

//app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.UseStaticFiles();

app.MapControllers();

// ✅ DODANO: mapiranje SignalR Hub-a
app.MapHub<ChatHub>("/hubs/chat");

app.Run();
