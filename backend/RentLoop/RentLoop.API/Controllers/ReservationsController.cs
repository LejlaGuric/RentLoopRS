using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;
using RentLoop.API.DTOs.Reservations;
using RentLoop.API.Models;
using System.Security.Claims;

namespace RentLoop.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ReservationsController : ControllerBase
    {
        private readonly ApplicationDbContext _db;

        public ReservationsController(ApplicationDbContext db)
        {
            _db = db;
        }

        private int GetUserId()
        {
            var id = User.FindFirstValue(ClaimTypes.NameIdentifier)
                     ?? User.FindFirstValue("sub");

            if (string.IsNullOrWhiteSpace(id))
                throw new Exception("Invalid token.");

            return int.Parse(id);
        }

        // CLIENT — create reservation (PENDING)
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] ReservationCreateRequest request)
        {
            var userId = GetUserId();

            if (request.CheckOut <= request.CheckIn)
                return BadRequest("Check-out must be after check-in.");

            var listing = await _db.Listings.FirstOrDefaultAsync(l => l.Id == request.ListingId && l.IsActive);
            if (listing == null) return NotFound("Listing not found.");

            var days = (request.CheckOut - request.CheckIn).Days;
            if (days <= 0) return BadRequest("Invalid date range.");

            var totalPrice = days * listing.PricePerNight;

            var overlap = await _db.Reservations.AnyAsync(r =>
                r.PropertyId == listing.Id &&
                (r.StatusId == 1 || r.StatusId == 2) && // Pending ili Approved
                request.CheckIn < r.CheckOut &&
                request.CheckOut > r.CheckIn);

            if (overlap)
                return BadRequest("Selected dates are not available.");

            var reservation = new Reservation
            {
                UserId = userId,
                PropertyId = listing.Id,
                CheckIn = request.CheckIn,
                CheckOut = request.CheckOut,
                Guests = request.Guests,
                TotalPrice = totalPrice,
                StatusId = 1, // Pending
                CreatedAt = DateTime.UtcNow,
                Note = request.Note
            };

            _db.Reservations.Add(reservation);
            await _db.SaveChangesAsync();

            return Ok(new { message = "Reservation created (pending approval)." });
        }

        // ✅ CLIENT — my reservations (jedan jedini endpoint!)
        // GET: api/reservations/my
        [HttpGet("my")]
        public async Task<IActionResult> MyReservations()
        {
            var userId = GetUserId();

            var data = await _db.Reservations
                .AsNoTracking()
                .Include(r => r.Status)
                .Include(r => r.Property)
                .Where(r => r.UserId == userId)
                .OrderByDescending(r => r.CreatedAt)
                .Select(r => new
                {
                    r.Id,
                    r.PropertyId,
                    r.CheckIn,
                    r.CheckOut,
                    r.Guests,
                    r.TotalPrice,
                    StatusId = r.StatusId,
                    Status = r.Status != null ? r.Status.Name : "",
                    r.CreatedAt,
                    Listing = r.Property == null ? null : new
                    {
                        r.Property.Id,
                        r.Property.Name
                    }
                })
                .ToListAsync();

            return Ok(data);
        }

        // ADMIN — pending reservations
        [HttpGet("pending")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Pending()
        {
            var data = await _db.Reservations
                .AsNoTracking()
                .Include(r => r.User)
                .Include(r => r.Property)
                .Include(r => r.Status)
                .Where(r => r.StatusId == 1)
                .OrderBy(r => r.CreatedAt)
                .Select(r => new
                {
                    r.Id,
                    r.CheckIn,
                    r.CheckOut,
                    r.TotalPrice,
                    Status = r.Status != null ? r.Status.Name : "",
                    User = r.User != null ? r.User.Username : "",
                    Listing = r.Property != null ? r.Property.Name : ""
                })
                .ToListAsync();

            return Ok(data);
        }

        // ADMIN — approve
        [HttpPut("{id:int}/approve")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Approve(int id)
        {
            var adminId = GetUserId();

            var r = await _db.Reservations
                .FirstOrDefaultAsync(x => x.Id == id);

            if (r == null) return NotFound();

            if (r.StatusId != 1)
                return BadRequest("Reservation is not pending.");

            r.StatusId = 2; // Approved
            r.ApprovedByAdminId = adminId;
            r.DecisionAt = DateTime.UtcNow;

            // Upiši zauzete dane (checkOut se ne računa kao noćenje)
            var start = r.CheckIn.Date;
            var end = r.CheckOut.Date;

            for (var d = start; d < end; d = d.AddDays(1))
            {
                _db.PropertyAvailability.Add(new PropertyAvailability
                {
                    PropertyId = r.PropertyId,
                    Date = d,
                    IsBooked = true,
                    ReservationId = r.Id
                });
            }

            await _db.SaveChangesAsync();

            return Ok(new { message = "Reservation approved and days booked." });
        }

        // ADMIN — all reservations (optional status)
        [HttpGet("admin")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> All([FromQuery] int? statusId)
        {
            var q = _db.Reservations
                .AsNoTracking()
                .Include(r => r.User)
                .Include(r => r.Property)
                .Include(r => r.Status)
                .OrderByDescending(r => r.CreatedAt)
                .AsQueryable();

            if (statusId.HasValue)
                q = q.Where(r => r.StatusId == statusId.Value);

            var data = await q.Select(r => new
            {
                r.Id,
                r.CheckIn,
                r.CheckOut,
                r.TotalPrice,
                StatusId = r.StatusId,
                Status = r.Status != null ? r.Status.Name : "",
                User = r.User != null ? r.User.Username : "",
                Listing = r.Property != null ? r.Property.Name : "",
                r.CreatedAt,
                r.Guests,
                r.Note
            }).ToListAsync();

            return Ok(data);
        }

        // ADMIN — reject
        [HttpPut("{id:int}/reject")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Reject(int id)
        {
            var adminId = GetUserId();

            var r = await _db.Reservations.FindAsync(id);
            if (r == null) return NotFound();

            r.StatusId = 3; // Rejected
            r.ApprovedByAdminId = adminId;
            r.DecisionAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();
            return Ok(new { message = "Reservation rejected." });
        }
    }
}
