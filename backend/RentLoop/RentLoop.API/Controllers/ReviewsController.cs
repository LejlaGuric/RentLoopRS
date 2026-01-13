using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;
using RentLoop.API.DTOs.Reviews;
using RentLoop.API.Models;
using System.Security.Claims;

namespace RentLoop.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize] // ulogovan korisnik
    public class ReviewsController : ControllerBase
    {
        private readonly ApplicationDbContext _db;

        public ReviewsController(ApplicationDbContext db)
        {
            _db = db;
        }

        private int GetUserId()
        {
            var id = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
            if (string.IsNullOrWhiteSpace(id)) throw new Exception("Invalid token.");
            return int.Parse(id);
        }

        // POST: api/reviews  (Client ostavlja review)
        [HttpPost]
        [Authorize(Roles = "Client")]
        public async Task<IActionResult> Create([FromBody] ReviewCreateRequest request)
        {
            var userId = GetUserId();

            if (request.Rating < 1 || request.Rating > 5)
                return BadRequest("Rating must be between 1 and 5.");

            // Učitaj rezervaciju
            var reservation = await _db.Reservations
                .FirstOrDefaultAsync(r => r.Id == request.ReservationId);

            if (reservation == null)
                return NotFound("Reservation not found.");

            // Mora biti njegova rezervacija
            if (reservation.UserId != userId)
                return Forbid("You can review only your reservation.");

            // Mora biti approved (statusId=2 po tvojoj logici)
            if (reservation.StatusId != 2)
                return BadRequest("You can review only approved reservations.");

            // Provjeri da već ne postoji review za tu rezervaciju
            var already = await _db.Reviews.AnyAsync(rv => rv.ReservationId == request.ReservationId);
            if (already)
                return BadRequest("Review already exists for this reservation.");

            var review = new Review
            {
                ReservationId = reservation.Id,
                PropertyId = reservation.PropertyId,
                UserId = userId,
                Rating = request.Rating,
                Comment = request.Comment,
                CreatedAt = DateTime.UtcNow
            };

            _db.Reviews.Add(review);
            await _db.SaveChangesAsync();

            return Ok(new { message = "Review added." });
        }

        // GET: api/reviews/listing/{listingId}  (svi review-i za stan)
        [HttpGet("listing/{listingId:int}")]
        [AllowAnonymous]
        public async Task<IActionResult> ForListing(int listingId)
        {
            var data = await _db.Reviews
                .AsNoTracking()
                .Where(r => r.PropertyId == listingId)
                .OrderByDescending(r => r.CreatedAt)
                .Select(r => new
                {
                    r.Id,
                    r.Rating,
                    r.Comment,
                    r.CreatedAt,
                    User = _db.Users.Where(u => u.Id == r.UserId).Select(u => u.Username).FirstOrDefault()
                })
                .ToListAsync();

            return Ok(data);
        }
    }
}
