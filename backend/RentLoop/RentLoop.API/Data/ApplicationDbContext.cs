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
        public DbSet<Payment> Payments { get; set; }

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

            modelBuilder.Entity<Payment>()
                .HasOne(p => p.User)
                .WithMany() // ako User nema kolekciju Payments
                .HasForeignKey(p => p.UserId)
                .OnDelete(DeleteBehavior.Restrict); // ✅ NO ACTION

            modelBuilder.Entity<Payment>()
                .HasOne(p => p.Reservation)
                .WithMany() // Reservation nema kolekciju Payments
                .HasForeignKey(p => p.ReservationId)
                .OnDelete(DeleteBehavior.Cascade); // ovo može ostati CASCADE

            // Conversation -> User (klijent)
            modelBuilder.Entity<Conversation>()
                .HasOne(c => c.User)
                .WithMany(u => u.ClientConversations)
                .HasForeignKey(c => c.UserId)
                .OnDelete(DeleteBehavior.NoAction);

            // Conversation -> Admin (dodijeljeni admin)
            modelBuilder.Entity<Conversation>()
                .HasOne(c => c.Admin)
                .WithMany(u => u.AdminConversations)
                .HasForeignKey(c => c.AdminId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Message>()
                .HasOne(m => m.Conversation)
                .WithMany(c => c.Messages)
                .HasForeignKey(m => m.ConversationId)
                .OnDelete(DeleteBehavior.Cascade);

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

            // ============================
            // SEED DATA (početni podaci)
            // ============================

            // Lookups
            modelBuilder.Entity<RentType>().HasData(
                new RentType { Id = 1, Name = "ShortTerm" },
                new RentType { Id = 2, Name = "LongTerm" }
            );

            modelBuilder.Entity<ReservationStatus>().HasData(
                new ReservationStatus { Id = 1, Name = "Pending" },
                new ReservationStatus { Id = 2, Name = "Approved" },
                new ReservationStatus { Id = 3, Name = "Rejected" }
            );

            modelBuilder.Entity<NotificationType>().HasData(
                new NotificationType { Id = 1, Name = "PriceDrop" },
                new NotificationType { Id = 2, Name = "ReservationApproved" },
                new NotificationType { Id = 3, Name = "ReservationRejected" },
                new NotificationType { Id = 4, Name = "Reminder" },
                new NotificationType { Id = 5, Name = "General" }
            );

            // Cities
            modelBuilder.Entity<City>().HasData(
                new City { Id = 1, Name = "Mostar" },
                new City { Id = 2, Name = "Sarajevo" },
                new City { Id = 3, Name = "Tuzla" },
                new City { Id = 4, Name = "Banja Luka" }
            );

            // Users
            // Users
            modelBuilder.Entity<User>().HasData(
                new User
                {
                    Id = 1,
                    Username = "admin",
                    Email = "admin@rentloop.com",
                    PasswordHash = "AQAAAAIAAYagAAAAEMRw5vgxTMvW08zOCvCTMu4hHp1VPdxSFwkFUDbdOiwMo/GAwIDM/EKFwr7tHuGfQQ==",
                    FirstName = "Admin",
                    LastName = "RentLoop",
                    Address = "Mostar",
                    Phone = "000-000",
                    Role = 1,
                    IsActive = true
                },
                new User
                {
                    Id = 2,
                    Username = "demo",
                    Email = "demo@rentloop.com",
                    PasswordHash = "AQAAAAIAAYagAAAAEM3ETeA/RYamGNigPexLLY0+LFq45A7YNMIh3Z33DDbie/i4U5DyIsN9QYL+G+aycA==",
                    FirstName = "Demo",
                    LastName = "User",
                    Address = "Sarajevo",
                    Phone = "061-111-222",
                    Role = 2,
                    IsActive = true
                }
            );


            // Amenities
            modelBuilder.Entity<Amenity>().HasData(
                new Amenity { Id = 1, Name = "Wi-Fi" },
                new Amenity { Id = 2, Name = "Parking" },
                new Amenity { Id = 3, Name = "Klima" },
                new Amenity { Id = 4, Name = "Lift" },
                new Amenity { Id = 5, Name = "Balkon" },
                new Amenity { Id = 6, Name = "Pogled" }
            );

       
        }
    }
}
