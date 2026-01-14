using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using RentLoop.API.Models;

namespace RentLoop.API.Data
{
    public static class DbSeeder
    {
        public static async Task SeedAsync(ApplicationDbContext db)
        {
            // ADMIN
            if (!await db.Users.AnyAsync(u => u.Email == "admin@rentloop.com"))
            {
                var hasher = new PasswordHasher<User>();

                var admin = new User
                {
                    Username = "admin",
                    Email = "admin@rentloop.com",
                    FirstName = "Admin",
                    LastName = "RentLoop",
                    Address = "Mostar",
                    Phone = "000-000",
                    Role = 1,
                    IsActive = true
                };

                admin.PasswordHash = hasher.HashPassword(admin, "Admin123!");
                db.Users.Add(admin);
            }

            // DEMO USER
            if (!await db.Users.AnyAsync(u => u.Email == "demo@rentloop.com"))
            {
                var hasher = new PasswordHasher<User>();

                var demo = new User
                {
                    Username = "demo",
                    Email = "demo@rentloop.com",
                    FirstName = "Demo",
                    LastName = "User",
                    Address = "Sarajevo",
                    Phone = "061-111-222",
                    Role = 2,
                    IsActive = true
                };

                demo.PasswordHash = hasher.HashPassword(demo, "Demo123!");
                db.Users.Add(demo);
            }

            await db.SaveChangesAsync();
        }
    }
}
