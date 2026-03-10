using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;
using RentLoop.API.DTOs.Reservations;
using RentLoop.API.Models;
using System.Security.Claims;
using RentLoop.API.Messaging;

namespace RentLoop.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ReservationsController : ControllerBase
    {
        private readonly ApplicationDbContext _db;
        private readonly RabbitMqPublisher _mq;

        public ReservationsController(ApplicationDbContext db, RabbitMqPublisher mq)
        {
            _db = db;
            _mq = mq;
        }

        private int GetUserId()
        {
            var id = User.FindFirstValue(ClaimTypes.NameIdentifier)
                     ?? User.FindFirstValue("sub");

            if (string.IsNullOrWhiteSpace(id))
                return 0;

            if (!int.TryParse(id, out var userId))
                return 0;

            return userId;
        }

        // CLIENT — create reservation (PENDING)
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] ReservationCreateRequest request)
        {
            var userId = GetUserId();
            if (userId == 0)
                return Unauthorized();

            if (request.CheckOut <= request.CheckIn)
                return BadRequest("Check-out must be after check-in.");

            var listing = await _db.Listings.FirstOrDefaultAsync(l => l.Id == request.ListingId && l.IsActive);
            if (listing == null)
                return NotFound("Listing not found.");

            if (request.Guests <= 0)
                return BadRequest("Guests must be greater than 0.");

            if (request.Guests > listing.MaxGuests)
                return BadRequest($"Maximum allowed guests for this listing is {listing.MaxGuests}.");

            var days = (request.CheckOut - request.CheckIn).Days;
            if (days <= 0)
                return BadRequest("Invalid date range.");

            var totalPrice = days * listing.PricePerNight;

            var overlap = await _db.Reservations.AnyAsync(r =>
                r.PropertyId == listing.Id &&
                (r.StatusId == 1 || r.StatusId == 2) &&
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
                StatusId = 1,
                CreatedAt = DateTime.UtcNow,
                Note = request.Note
            };

            _db.Reservations.Add(reservation);
            await _db.SaveChangesAsync();

            return Ok(new { message = "Reservation created (pending approval)." });
        }

        // CLIENT — my reservations
        [HttpGet("my")]
        public async Task<IActionResult> MyReservations()
        {
            var userId = GetUserId();
            if (userId == 0)
                return Unauthorized();

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
                    Nights = (r.CheckOut - r.CheckIn).Days,
                    r.Guests,
                    r.TotalPrice,

                    StatusId = r.StatusId,
                    Status = r.Status != null ? r.Status.Name : "",

                    r.CreatedAt,
                    r.Note,

                    IsPaid = r.IsPaid,
                    PaidAt = r.PaidAt,

                    CanPay = r.StatusId == 2 && !r.IsPaid,
                    CanCancel = r.StatusId == 1,

                    Listing = r.Property == null ? null : new
                    {
                        r.Property.Id,
                        r.Property.Name,
                        r.Property.PricePerNight,
                        City = _db.Cities
                            .Where(c => c.Id == r.Property.CityId)
                            .Select(c => c.Name)
                            .FirstOrDefault(),

                        CoverUrl = _db.PropertyImages
                            .Where(pi => pi.PropertyId == r.Property.Id && pi.IsCover)
                            .Select(pi => pi.Url)
                            .FirstOrDefault()
                            ?? _db.PropertyImages
                                .Where(pi => pi.PropertyId == r.Property.Id)
                                .OrderBy(pi => pi.SortOrder)
                                .Select(pi => pi.Url)
                                .FirstOrDefault()
                    }
                })
                .ToListAsync();

            return Ok(data);
        }

        // CLIENT — cancel reservation
        [HttpPut("{id:int}/cancel")]
        public async Task<IActionResult> Cancel(int id)
        {
            var userId = GetUserId();
            if (userId == 0)
                return Unauthorized();

            var r = await _db.Reservations
                .FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId);

            if (r == null)
                return NotFound("Reservation not found.");

            if (r.StatusId == 3)
                return BadRequest("Reservation is already rejected.");

            if (r.StatusId == 4)
                return BadRequest("Reservation is already cancelled.");

            if (r.StatusId != 1)
                return BadRequest("Only pending reservations can be cancelled.");

            r.StatusId = 4;
            r.DecisionAt = DateTime.UtcNow;

            var availabilityRows = await _db.PropertyAvailability
                .Where(a => a.ReservationId == r.Id)
                .ToListAsync();

            if (availabilityRows.Count > 0)
                _db.PropertyAvailability.RemoveRange(availabilityRows);

            await _db.SaveChangesAsync();

            return Ok(new { message = "Reservation cancelled." });
        }

        // ADMIN — pending reservations
        [HttpGet("pending")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Pending()
        {
            var adminId = GetUserId();
            if (adminId == 0)
                return Unauthorized();

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
            if (adminId == 0)
                return Unauthorized();

            var r = await _db.Reservations
                .FirstOrDefaultAsync(x => x.Id == id);

            if (r == null)
                return NotFound();

            if (r.StatusId != 1)
                return BadRequest("Reservation is not pending.");

            var overlapExists = await _db.Reservations.AnyAsync(x =>
                x.Id != r.Id &&
                x.PropertyId == r.PropertyId &&
                x.StatusId == 2 &&
                r.CheckIn < x.CheckOut &&
                r.CheckOut > x.CheckIn);

            if (overlapExists)
                return BadRequest("Selected dates are no longer available.");

            r.StatusId = 2;
            r.ApprovedByAdminId = adminId;
            r.DecisionAt = DateTime.UtcNow;

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

            _mq.PublishReservationApproved(new
            {
                ReservationId = r.Id,
                UserId = r.UserId,
                PropertyId = r.PropertyId,
                CheckIn = r.CheckIn,
                CheckOut = r.CheckOut,
                TotalPrice = r.TotalPrice,
                ApprovedByAdminId = adminId,
                DecisionAt = r.DecisionAt
            });

            return Ok(new { message = "Reservation approved and days booked." });
        }

        // ADMIN — all reservations (optional status)
        [HttpGet("admin")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> All([FromQuery] int? statusId)
        {
            var adminId = GetUserId();
            if (adminId == 0)
                return Unauthorized();

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
                r.Note,
                r.IsPaid,
                r.PaidAt
            }).ToListAsync();

            return Ok(data);
        }

        // ADMIN — reject
        [HttpPut("{id:int}/reject")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Reject(int id)
        {
            var adminId = GetUserId();
            if (adminId == 0)
                return Unauthorized();

            var r = await _db.Reservations.FindAsync(id);
            if (r == null)
                return NotFound();

            if (r.StatusId != 1)
                return BadRequest("Only pending reservations can be rejected.");

            r.StatusId = 3;
            r.ApprovedByAdminId = adminId;
            r.DecisionAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();
            return Ok(new { message = "Reservation rejected." });
        }
    }
}