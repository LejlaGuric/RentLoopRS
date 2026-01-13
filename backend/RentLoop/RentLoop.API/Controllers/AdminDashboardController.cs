using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;

namespace RentLoop.API.Controllers
{
    [ApiController]
    [Route("api/admin/dashboard")]
    [Authorize(Roles = "Admin")]
    public class AdminDashboardController : ControllerBase
    {
        private readonly ApplicationDbContext _db;

        public AdminDashboardController(ApplicationDbContext db)
        {
            _db = db;
        }

        [HttpGet]
        public async Task<IActionResult> GetStats()
        {
            var usersCount = await _db.Users.CountAsync();
            var activeUsersCount = await _db.Users.CountAsync(u => u.IsActive);
            var listingsCount = await _db.Listings.CountAsync();
            var reservationsCount = await _db.Reservations.CountAsync();
            var pendingReservations = await _db.Reservations.CountAsync(r => r.StatusId == 1);

            var avgRating = await _db.Reviews
                .Select(r => (double?)r.Rating)
                .AverageAsync() ?? 0;

            return Ok(new
            {
                usersCount,
                activeUsersCount,
                listingsCount,
                reservationsCount,
                pendingReservations,
                avgRating = Math.Round(avgRating, 2)
            });
        }
    }
}
