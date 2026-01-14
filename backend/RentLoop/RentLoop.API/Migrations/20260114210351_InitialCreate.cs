using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace RentLoop.API.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Amenities",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Amenities", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Cities",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Cities", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "NotificationTypes",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NotificationTypes", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "RentTypes",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RentTypes", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "ReservationStatuses",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ReservationStatuses", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Users",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Username = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    Email = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    PasswordHash = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    FirstName = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    LastName = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Address = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Phone = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Role = table.Column<int>(type: "int", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Users", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Listings",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Address = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CityId = table.Column<int>(type: "int", nullable: false),
                    RentTypeId = table.Column<int>(type: "int", nullable: false),
                    PricePerNight = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    RoomsCount = table.Column<int>(type: "int", nullable: false),
                    MaxGuests = table.Column<int>(type: "int", nullable: false),
                    DistanceToCenterKm = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    HasWifi = table.Column<bool>(type: "bit", nullable: false),
                    HasAirConditioning = table.Column<bool>(type: "bit", nullable: false),
                    PetsAllowed = table.Column<bool>(type: "bit", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Listings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Listings_Cities_CityId",
                        column: x => x.CityId,
                        principalTable: "Cities",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Listings_RentTypes_RentTypeId",
                        column: x => x.RentTypeId,
                        principalTable: "RentTypes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Conversations",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    AdminId = table.Column<int>(type: "int", nullable: true),
                    LastMessageAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Conversations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Conversations_Users_AdminId",
                        column: x => x.AdminId,
                        principalTable: "Users",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_Conversations_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "SearchHistory",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    CityId = table.Column<int>(type: "int", nullable: true),
                    RentTypeId = table.Column<int>(type: "int", nullable: true),
                    MinPrice = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: true),
                    MaxPrice = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: true),
                    RoomsCount = table.Column<int>(type: "int", nullable: true),
                    Guests = table.Column<int>(type: "int", nullable: true),
                    Sort = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    SearchedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SearchHistory", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SearchHistory_Cities_CityId",
                        column: x => x.CityId,
                        principalTable: "Cities",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_SearchHistory_RentTypes_RentTypeId",
                        column: x => x.RentTypeId,
                        principalTable: "RentTypes",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_SearchHistory_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Favorites",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    PropertyId = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Favorites", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Favorites_Listings_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "Listings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Favorites_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ListingViews",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    ListingId = table.Column<int>(type: "int", nullable: false),
                    ViewedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ListingViews", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ListingViews_Listings_ListingId",
                        column: x => x.ListingId,
                        principalTable: "Listings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ListingViews_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PropertyAmenities",
                columns: table => new
                {
                    PropertyId = table.Column<int>(type: "int", nullable: false),
                    AmenityId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PropertyAmenities", x => new { x.PropertyId, x.AmenityId });
                    table.ForeignKey(
                        name: "FK_PropertyAmenities_Amenities_AmenityId",
                        column: x => x.AmenityId,
                        principalTable: "Amenities",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PropertyAmenities_Listings_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "Listings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PropertyImages",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PropertyId = table.Column<int>(type: "int", nullable: false),
                    Url = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    IsCover = table.Column<bool>(type: "bit", nullable: false),
                    SortOrder = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PropertyImages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PropertyImages_Listings_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "Listings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Reservations",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    PropertyId = table.Column<int>(type: "int", nullable: false),
                    CheckIn = table.Column<DateTime>(type: "datetime2", nullable: false),
                    CheckOut = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Guests = table.Column<int>(type: "int", nullable: false),
                    TotalPrice = table.Column<decimal>(type: "decimal(18,2)", precision: 18, scale: 2, nullable: false),
                    IsPaid = table.Column<bool>(type: "bit", nullable: false),
                    PaidAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    StatusId = table.Column<int>(type: "int", nullable: false),
                    ApprovedByAdminId = table.Column<int>(type: "int", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    DecisionAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Note = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Reservations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Reservations_Listings_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "Listings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Reservations_ReservationStatuses_StatusId",
                        column: x => x.StatusId,
                        principalTable: "ReservationStatuses",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Reservations_Users_ApprovedByAdminId",
                        column: x => x.ApprovedByAdminId,
                        principalTable: "Users",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_Reservations_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Messages",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ConversationId = table.Column<int>(type: "int", nullable: false),
                    SenderUserId = table.Column<int>(type: "int", nullable: false),
                    Text = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    SentAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsRead = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Messages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Messages_Conversations_ConversationId",
                        column: x => x.ConversationId,
                        principalTable: "Conversations",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Messages_Users_SenderUserId",
                        column: x => x.SenderUserId,
                        principalTable: "Users",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "Notifications",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    TypeId = table.Column<int>(type: "int", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Body = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    IsRead = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    RelatedPropertyId = table.Column<int>(type: "int", nullable: true),
                    RelatedReservationId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Notifications", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Notifications_Listings_RelatedPropertyId",
                        column: x => x.RelatedPropertyId,
                        principalTable: "Listings",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_Notifications_NotificationTypes_TypeId",
                        column: x => x.TypeId,
                        principalTable: "NotificationTypes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Notifications_Reservations_RelatedReservationId",
                        column: x => x.RelatedReservationId,
                        principalTable: "Reservations",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_Notifications_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Payments",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    ReservationId = table.Column<int>(type: "int", nullable: false),
                    Provider = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ProviderOrderId = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Amount = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    Currency = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    CapturedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Payments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Payments_Reservations_ReservationId",
                        column: x => x.ReservationId,
                        principalTable: "Reservations",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Payments_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "PropertyAvailability",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    PropertyId = table.Column<int>(type: "int", nullable: false),
                    Date = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsBooked = table.Column<bool>(type: "bit", nullable: false),
                    ReservationId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PropertyAvailability", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PropertyAvailability_Listings_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "Listings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PropertyAvailability_Reservations_ReservationId",
                        column: x => x.ReservationId,
                        principalTable: "Reservations",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "Reviews",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ReservationId = table.Column<int>(type: "int", nullable: false),
                    PropertyId = table.Column<int>(type: "int", nullable: false),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    Rating = table.Column<int>(type: "int", nullable: false),
                    Comment = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Reviews", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Reviews_Listings_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "Listings",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_Reviews_Reservations_ReservationId",
                        column: x => x.ReservationId,
                        principalTable: "Reservations",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Reviews_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id");
                });

            migrationBuilder.InsertData(
                table: "Amenities",
                columns: new[] { "Id", "Name" },
                values: new object[,]
                {
                    { 1, "Wi-Fi" },
                    { 2, "Parking" },
                    { 3, "Klima" },
                    { 4, "Lift" },
                    { 5, "Balkon" },
                    { 6, "Pogled" }
                });

            migrationBuilder.InsertData(
                table: "Cities",
                columns: new[] { "Id", "Name" },
                values: new object[,]
                {
                    { 1, "Mostar" },
                    { 2, "Sarajevo" },
                    { 3, "Tuzla" },
                    { 4, "Banja Luka" }
                });

            migrationBuilder.InsertData(
                table: "NotificationTypes",
                columns: new[] { "Id", "Name" },
                values: new object[,]
                {
                    { 1, "PriceDrop" },
                    { 2, "ReservationApproved" },
                    { 3, "ReservationRejected" },
                    { 4, "Reminder" },
                    { 5, "General" }
                });

            migrationBuilder.InsertData(
                table: "RentTypes",
                columns: new[] { "Id", "Name" },
                values: new object[,]
                {
                    { 1, "ShortTerm" },
                    { 2, "LongTerm" }
                });

            migrationBuilder.InsertData(
                table: "ReservationStatuses",
                columns: new[] { "Id", "Name" },
                values: new object[,]
                {
                    { 1, "Pending" },
                    { 2, "Approved" },
                    { 3, "Rejected" }
                });

            migrationBuilder.InsertData(
                table: "Users",
                columns: new[] { "Id", "Address", "Email", "FirstName", "IsActive", "LastName", "PasswordHash", "Phone", "Role", "Username" },
                values: new object[,]
                {
                    { 1, "Mostar", "admin@rentloop.com", "Admin", true, "RentLoop", "AQAAAAIAAYagAAAAEMRw5vgxTMvW08zOCvCTMu4hHp1VPdxSFwkFUDbdOiwMo/GAwIDM/EKFwr7tHuGfQQ==", "000-000", 1, "admin" },
                    { 2, "Sarajevo", "demo@rentloop.com", "Demo", true, "User", "AQAAAAIAAYagAAAAEM3ETeA/RYamGNigPexLLY0+LFq45A7YNMIh3Z33DDbie/i4U5DyIsN9QYL+G+aycA==", "061-111-222", 0, "demo" }
                });

            migrationBuilder.InsertData(
                table: "Listings",
                columns: new[] { "Id", "Address", "CityId", "CreatedAt", "Description", "DistanceToCenterKm", "HasAirConditioning", "HasWifi", "IsActive", "MaxGuests", "Name", "PetsAllowed", "PricePerNight", "RentTypeId", "RoomsCount" },
                values: new object[,]
                {
                    { 1, "Kneza Domagoja 12", 1, new DateTime(2025, 1, 10, 12, 0, 0, 0, DateTimeKind.Utc), "Moderan studio blizu Starog mosta. Idealan za parove i kratki boravak.", 0.60m, true, true, true, 2, "Sunset Studio – Centar Mostara", false, 85.00m, 1, 1 },
                    { 2, "Maršala Tita 44", 1, new DateTime(2025, 1, 12, 12, 0, 0, 0, DateTimeKind.Utc), "Svijetao apartman s pogledom, mirna zgrada, odlična lokacija.", 1.20m, false, true, true, 4, "Neretva View Apartment", true, 110.00m, 1, 2 },
                    { 3, "Zelenih beretki 7", 2, new DateTime(2025, 1, 15, 12, 0, 0, 0, DateTimeKind.Utc), "U srcu starog grada – sve je na pješačkoj udaljenosti. Toplo i udobno.", 0.30m, true, true, true, 3, "Baščaršija Cozy Stay", false, 95.00m, 1, 1 },
                    { 4, "Hamdije Kreševljakovića 18", 2, new DateTime(2025, 1, 18, 12, 0, 0, 0, DateTimeKind.Utc), "Praktičan stan za duži boravak, dobar prevoz i mirna lokacija.", 1.00m, false, true, true, 4, "Business Flat – Sarajevo Center", true, 60.00m, 2, 2 },
                    { 5, "Slatina 21", 3, new DateTime(2025, 1, 20, 12, 0, 0, 0, DateTimeKind.Utc), "Prostran stan za porodice, mirno naselje, blizina prodavnica i parka.", 1.80m, true, true, true, 6, "Tuzla Family Comfort", true, 75.00m, 1, 3 },
                    { 6, "Kralja Petra I 9", 4, new DateTime(2025, 1, 22, 12, 0, 0, 0, DateTimeKind.Utc), "Minimalistički loft, čist dizajn, idealan za city break.", 0.90m, true, true, true, 2, "Banja Luka Minimal Loft", false, 88.00m, 1, 1 }
                });

            migrationBuilder.InsertData(
                table: "PropertyAmenities",
                columns: new[] { "AmenityId", "PropertyId" },
                values: new object[,]
                {
                    { 1, 1 },
                    { 3, 1 },
                    { 5, 1 },
                    { 1, 2 },
                    { 2, 2 },
                    { 6, 2 },
                    { 1, 3 },
                    { 4, 3 },
                    { 6, 3 },
                    { 1, 4 },
                    { 2, 4 },
                    { 1, 5 },
                    { 2, 5 },
                    { 5, 5 },
                    { 1, 6 },
                    { 3, 6 },
                    { 6, 6 }
                });

            migrationBuilder.InsertData(
                table: "PropertyImages",
                columns: new[] { "Id", "IsCover", "PropertyId", "SortOrder", "Url" },
                values: new object[,]
                {
                    { 1, true, 1, 0, "https://dupqmgrdwnev6.cloudfront.net/wp-content/uploads/2018/04/Pinterest-sadf-930x697.jpg?x60971" },
                    { 2, false, 1, 1, "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSwFAeh2TrHWJ__9LhnRz4cYa5xWmJc_7GQEw&s" },
                    { 3, false, 1, 2, "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR7hkXlEgH4y-vRg38k0I6XjZoWZmI5z813Dw&s" },
                    { 4, true, 2, 0, "https://www.mojstan.net/wp-content/uploads/2014/11/simpatican-stan-povrsine-40-kvadrata-2.jpg" },
                    { 5, false, 2, 1, "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR7hkXlEgH4y-vRg38k0I6XjZoWZmI5z813Dw&s" },
                    { 6, false, 2, 2, "https://dupqmgrdwnev6.cloudfront.net/wp-content/uploads/2018/12/Mali-stan-Moskva-15-e1544544438756-930x615.jpg?x60971" },
                    { 7, true, 3, 0, "https://dupqmgrdwnev6.cloudfront.net/wp-content/uploads/2018/12/Mali-stan-Moskva-15-e1544544438756-930x615.jpg?x60971" },
                    { 8, false, 3, 1, "https://dupqmgrdwnev6.cloudfront.net/wp-content/uploads/2021/06/Divan-mali-stan-za-najam.jpg-11-930x697.jpg?x60971" },
                    { 9, false, 3, 2, "https://dupqmgrdwnev6.cloudfront.net/wp-content/uploads/2021/06/Divan-mali-stan-za-najam.jpg-11-930x697.jpg?x60971" },
                    { 10, true, 4, 0, "https://www.kucastil.rs/uploads/ck_editor/images/clanci/ENTERIJER/Sjajna%20re%C5%A1enja%20za%20stanove%20do%2040%20m%C2%B2%20DETALJAN%20PLAN/Sjajna%20re%C5%A1enja%20za%20stanove%20do%2040%20m%C2%B2%20ll%20(6).jpg" },
                    { 11, false, 4, 1, "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSgcC_TwoxChv1vFapfVryyw7qT009JC-oLtw&s" },
                    { 12, false, 4, 2, "https://dupqmgrdwnev6.cloudfront.net/wp-content/uploads/2021/06/Divan-mali-stan-za-najam.jpg-11-930x697.jpg?x60971" },
                    { 13, true, 5, 0, "https://www.mojstan.net/wp-content/uploads/2013/12/kreativni-stan-od-40-m2-2.jpg" },
                    { 14, false, 5, 1, "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSgcC_TwoxChv1vFapfVryyw7qT009JC-oLtw&s" },
                    { 15, false, 5, 2, "https://dupqmgrdwnev6.cloudfront.net/wp-content/uploads/2021/06/Divan-mali-stan-za-najam.jpg-11-930x697.jpg?x60971" },
                    { 16, true, 6, 0, "https://www.mojstan.net/wp-content/uploads/2013/12/kreativni-stan-od-40-m2-2.jpg" },
                    { 17, false, 6, 1, "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSgcC_TwoxChv1vFapfVryyw7qT009JC-oLtw&s" },
                    { 18, false, 6, 2, "https://dupqmgrdwnev6.cloudfront.net/wp-content/uploads/2021/06/Divan-mali-stan-za-najam.jpg-11-930x697.jpg?x60971" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_Conversations_AdminId",
                table: "Conversations",
                column: "AdminId");

            migrationBuilder.CreateIndex(
                name: "IX_Conversations_UserId",
                table: "Conversations",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Favorites_PropertyId",
                table: "Favorites",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_Favorites_UserId_PropertyId",
                table: "Favorites",
                columns: new[] { "UserId", "PropertyId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Listings_CityId",
                table: "Listings",
                column: "CityId");

            migrationBuilder.CreateIndex(
                name: "IX_Listings_RentTypeId",
                table: "Listings",
                column: "RentTypeId");

            migrationBuilder.CreateIndex(
                name: "IX_ListingViews_ListingId",
                table: "ListingViews",
                column: "ListingId");

            migrationBuilder.CreateIndex(
                name: "IX_ListingViews_UserId",
                table: "ListingViews",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Messages_ConversationId",
                table: "Messages",
                column: "ConversationId");

            migrationBuilder.CreateIndex(
                name: "IX_Messages_SenderUserId",
                table: "Messages",
                column: "SenderUserId");

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_RelatedPropertyId",
                table: "Notifications",
                column: "RelatedPropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_RelatedReservationId",
                table: "Notifications",
                column: "RelatedReservationId");

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_TypeId",
                table: "Notifications",
                column: "TypeId");

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_UserId",
                table: "Notifications",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_ReservationId",
                table: "Payments",
                column: "ReservationId");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_UserId",
                table: "Payments",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyAmenities_AmenityId",
                table: "PropertyAmenities",
                column: "AmenityId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyAvailability_PropertyId_Date",
                table: "PropertyAvailability",
                columns: new[] { "PropertyId", "Date" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PropertyAvailability_ReservationId",
                table: "PropertyAvailability",
                column: "ReservationId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyImages_PropertyId",
                table: "PropertyImages",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_ApprovedByAdminId",
                table: "Reservations",
                column: "ApprovedByAdminId");

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_PropertyId",
                table: "Reservations",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_StatusId",
                table: "Reservations",
                column: "StatusId");

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_UserId",
                table: "Reservations",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_PropertyId",
                table: "Reviews",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_ReservationId",
                table: "Reviews",
                column: "ReservationId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_UserId",
                table: "Reviews",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_SearchHistory_CityId",
                table: "SearchHistory",
                column: "CityId");

            migrationBuilder.CreateIndex(
                name: "IX_SearchHistory_RentTypeId",
                table: "SearchHistory",
                column: "RentTypeId");

            migrationBuilder.CreateIndex(
                name: "IX_SearchHistory_UserId",
                table: "SearchHistory",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Users_Email",
                table: "Users",
                column: "Email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Users_Username",
                table: "Users",
                column: "Username",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Favorites");

            migrationBuilder.DropTable(
                name: "ListingViews");

            migrationBuilder.DropTable(
                name: "Messages");

            migrationBuilder.DropTable(
                name: "Notifications");

            migrationBuilder.DropTable(
                name: "Payments");

            migrationBuilder.DropTable(
                name: "PropertyAmenities");

            migrationBuilder.DropTable(
                name: "PropertyAvailability");

            migrationBuilder.DropTable(
                name: "PropertyImages");

            migrationBuilder.DropTable(
                name: "Reviews");

            migrationBuilder.DropTable(
                name: "SearchHistory");

            migrationBuilder.DropTable(
                name: "Conversations");

            migrationBuilder.DropTable(
                name: "NotificationTypes");

            migrationBuilder.DropTable(
                name: "Amenities");

            migrationBuilder.DropTable(
                name: "Reservations");

            migrationBuilder.DropTable(
                name: "Listings");

            migrationBuilder.DropTable(
                name: "ReservationStatuses");

            migrationBuilder.DropTable(
                name: "Users");

            migrationBuilder.DropTable(
                name: "Cities");

            migrationBuilder.DropTable(
                name: "RentTypes");
        }
    }
}
