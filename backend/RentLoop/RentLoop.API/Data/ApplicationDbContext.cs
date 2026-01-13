using Microsoft.EntityFrameworkCore;
using RentLoop.API.Models;

namespace RentLoop.API.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options) { }

        public DbSet<User> Users => Set<User>();
        public DbSet<City> Cities => Set<City>();
        public DbSet<RentType> RentTypes => Set<RentType>();
        public DbSet<PropertyImage> PropertyImages => Set<PropertyImage>();
        public DbSet<Listing> Listings => Set<Listing>();

        public DbSet<Amenity> Amenities => Set<Amenity>();
        public DbSet<PropertyAmenity> PropertyAmenities => Set<PropertyAmenity>();

        public DbSet<Reservation> Reservations => Set<Reservation>();
        public DbSet<ReservationStatus> ReservationStatuses => Set<ReservationStatus>();
        public DbSet<PropertyAvailability> PropertyAvailability => Set<PropertyAvailability>();
        public DbSet<Review> Reviews => Set<Review>();

        public DbSet<Favorite> Favorites => Set<Favorite>();
        public DbSet<SearchHistory> SearchHistory => Set<SearchHistory>();

        public DbSet<ListingView> ListingViews { get; set; }

        public DbSet<Conversation> Conversations => Set<Conversation>();
        public DbSet<Message> Messages => Set<Message>();

        public DbSet<Notification> Notifications => Set<Notification>();
        public DbSet<NotificationType> NotificationTypes => Set<NotificationType>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Unique constraints (preporuka)
            modelBuilder.Entity<User>()
                .HasIndex(x => x.Username)
                .IsUnique();

            modelBuilder.Entity<User>()
                .HasIndex(x => x.Email)
                .IsUnique();

            // N-N: PropertyAmenity composite key
            modelBuilder.Entity<PropertyAmenity>()
                .HasKey(x => new { x.PropertyId, x.AmenityId });

            // Reservation -> ApprovedByAdmin (self reference)
            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.ApprovedByAdmin)
                .WithMany()
                .HasForeignKey(r => r.ApprovedByAdminId)
                .OnDelete(DeleteBehavior.NoAction);

            // Conversation -> Admin (self ref)
            modelBuilder.Entity<Conversation>()
                .HasOne(c => c.Admin)
                .WithMany()
                .HasForeignKey(c => c.AdminId)
                .OnDelete(DeleteBehavior.NoAction);

            // Message -> SenderUser (self ref)
            modelBuilder.Entity<Message>()
                .HasOne(m => m.SenderUser)
                .WithMany(u => u.SentMessages)
                .HasForeignKey(m => m.SenderUserId)
                .OnDelete(DeleteBehavior.NoAction);

            // Review: 1 reservation -> 0/1 review
            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.Review)
                .WithOne(rv => rv.Reservation)
                .HasForeignKey<Review>(rv => rv.ReservationId)
                .OnDelete(DeleteBehavior.Cascade);

            // Availability: (PropertyId, Date) unique (da nema duplih dana)
            modelBuilder.Entity<PropertyAvailability>()
                .HasIndex(a => new { a.PropertyId, a.Date })
                .IsUnique();

            // DECIMAL precision (SQL Server)
            modelBuilder.Entity<Listing>()
                .Property(x => x.PricePerNight)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Listing>()
                .Property(x => x.DistanceToCenterKm)
                .HasPrecision(10, 2);

            modelBuilder.Entity<Reservation>()
                .Property(x => x.TotalPrice)
                .HasPrecision(18, 2);

            modelBuilder.Entity<SearchHistory>()
                .Property(x => x.MinPrice)
                .HasPrecision(18, 2);

            modelBuilder.Entity<SearchHistory>()
                .Property(x => x.MaxPrice)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Review>()
                .HasOne(r => r.User)
                .WithMany()
                .HasForeignKey(r => r.UserId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Review>()
                .HasOne(r => r.Property)
                .WithMany(l => l.Reviews)
                .HasForeignKey(r => r.PropertyId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Favorite>()
                .HasIndex(f => new { f.UserId, f.PropertyId })
                .IsUnique();


            // SEED DATA (početni podaci)
            modelBuilder.Entity<RentType>().HasData(
                new RentType { Id = 1, Name = "ShortTerm" },
                new RentType { Id = 2, Name = "LongTerm" }
            );

            modelBuilder.Entity<ReservationStatus>().HasData(
                new ReservationStatus { Id = 1, Name = "Pending" },
                new ReservationStatus { Id = 2, Name = "Approved" },
                new ReservationStatus { Id = 3, Name = "Rejected" },
                new ReservationStatus { Id = 4, Name = "Cancelled" }
            );

            modelBuilder.Entity<NotificationType>().HasData(
                new NotificationType { Id = 1, Name = "PriceDrop" },
                new NotificationType { Id = 2, Name = "ReservationApproved" },
                new NotificationType { Id = 3, Name = "ReservationRejected" },
                new NotificationType { Id = 4, Name = "Reminder" },
                new NotificationType { Id = 5, Name = "General" }
            );

            // Admin user (Role=1)
            modelBuilder.Entity<User>().HasData(
                new User
                {
                    Id = 1,
                    Username = "admin",
                    Email = "admin@rentloop.com",
                    PasswordHash = "admin", // privremeno; kasnije hash/JWT
                    FirstName = "Admin",
                    LastName = "RentLoop",
                    Address = "Mostar",
                    Phone = "000-000",
                    Role = 1,
                    IsActive = true
                }
            );


        }
    }
}
