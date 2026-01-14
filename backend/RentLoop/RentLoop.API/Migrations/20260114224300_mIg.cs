using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace RentLoop.API.Migrations
{
    /// <inheritdoc />
    public partial class mIg : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "PropertyAmenities",
                keyColumns: new[] { "AmenityId", "PropertyId" },
                keyValues: new object[] { 1, 1 });

            migrationBuilder.DeleteData(
                table: "PropertyAmenities",
                keyColumns: new[] { "AmenityId", "PropertyId" },
                keyValues: new object[] { 3, 1 });

            migrationBuilder.DeleteData(
                table: "PropertyAmenities",
                keyColumns: new[] { "AmenityId", "PropertyId" },
                keyValues: new object[] { 5, 1 });

            migrationBuilder.DeleteData(
                table: "PropertyAmenities",
                keyColumns: new[] { "AmenityId", "PropertyId" },
                keyValues: new object[] { 1, 2 });

            migrationBuilder.DeleteData(
                table: "PropertyAmenities",
                keyColumns: new[] { "AmenityId", "PropertyId" },
                keyValues: new object[] { 2, 2 });

            migrationBuilder.DeleteData(
                table: "PropertyAmenities",
                keyColumns: new[] { "AmenityId", "PropertyId" },
                keyValues: new object[] { 6, 2 });

            migrationBuilder.DeleteData(
                table: "PropertyAmenities",
                keyColumns: new[] { "AmenityId", "PropertyId" },
                keyValues: new object[] { 1, 3 });

            migrationBuilder.DeleteData(
                table: "PropertyAmenities",
                keyColumns: new[] { "AmenityId", "PropertyId" },
                keyValues: new object[] { 4, 3 });

            migrationBuilder.DeleteData(
                table: "PropertyAmenities",
                keyColumns: new[] { "AmenityId", "PropertyId" },
                keyValues: new object[] { 6, 3 });

            migrationBuilder.DeleteData(
                table: "PropertyAmenities",
                keyColumns: new[] { "AmenityId", "PropertyId" },
                keyValues: new object[] { 1, 4 });

            migrationBuilder.DeleteData(
                table: "PropertyAmenities",
                keyColumns: new[] { "AmenityId", "PropertyId" },
                keyValues: new object[] { 2, 4 });

            migrationBuilder.DeleteData(
                table: "PropertyAmenities",
                keyColumns: new[] { "AmenityId", "PropertyId" },
                keyValues: new object[] { 1, 5 });

            migrationBuilder.DeleteData(
                table: "PropertyAmenities",
                keyColumns: new[] { "AmenityId", "PropertyId" },
                keyValues: new object[] { 2, 5 });

            migrationBuilder.DeleteData(
                table: "PropertyAmenities",
                keyColumns: new[] { "AmenityId", "PropertyId" },
                keyValues: new object[] { 5, 5 });

            migrationBuilder.DeleteData(
                table: "PropertyAmenities",
                keyColumns: new[] { "AmenityId", "PropertyId" },
                keyValues: new object[] { 1, 6 });

            migrationBuilder.DeleteData(
                table: "PropertyAmenities",
                keyColumns: new[] { "AmenityId", "PropertyId" },
                keyValues: new object[] { 3, 6 });

            migrationBuilder.DeleteData(
                table: "PropertyAmenities",
                keyColumns: new[] { "AmenityId", "PropertyId" },
                keyValues: new object[] { 6, 6 });

            migrationBuilder.DeleteData(
                table: "PropertyImages",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "PropertyImages",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "PropertyImages",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "PropertyImages",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "PropertyImages",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "PropertyImages",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.DeleteData(
                table: "PropertyImages",
                keyColumn: "Id",
                keyValue: 7);

            migrationBuilder.DeleteData(
                table: "PropertyImages",
                keyColumn: "Id",
                keyValue: 8);

            migrationBuilder.DeleteData(
                table: "PropertyImages",
                keyColumn: "Id",
                keyValue: 9);

            migrationBuilder.DeleteData(
                table: "PropertyImages",
                keyColumn: "Id",
                keyValue: 10);

            migrationBuilder.DeleteData(
                table: "PropertyImages",
                keyColumn: "Id",
                keyValue: 11);

            migrationBuilder.DeleteData(
                table: "PropertyImages",
                keyColumn: "Id",
                keyValue: 12);

            migrationBuilder.DeleteData(
                table: "PropertyImages",
                keyColumn: "Id",
                keyValue: 13);

            migrationBuilder.DeleteData(
                table: "PropertyImages",
                keyColumn: "Id",
                keyValue: 14);

            migrationBuilder.DeleteData(
                table: "PropertyImages",
                keyColumn: "Id",
                keyValue: 15);

            migrationBuilder.DeleteData(
                table: "PropertyImages",
                keyColumn: "Id",
                keyValue: 16);

            migrationBuilder.DeleteData(
                table: "PropertyImages",
                keyColumn: "Id",
                keyValue: 17);

            migrationBuilder.DeleteData(
                table: "PropertyImages",
                keyColumn: "Id",
                keyValue: 18);

            migrationBuilder.DeleteData(
                table: "Listings",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Listings",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Listings",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Listings",
                keyColumn: "Id",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "Listings",
                keyColumn: "Id",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "Listings",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 2,
                column: "Role",
                value: 2);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
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

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 2,
                column: "Role",
                value: 0);

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
        }
    }
}
