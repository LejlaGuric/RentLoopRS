using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;
using RentLoop.API.DTOs.Reservations;
using RentLoop.API.Models;
using System.Security.Claims;
using RentLoop.API.Messaging;
using RentLoop.API.Helpers;
using RentLoop.API.Services.Reservations;

namespace RentLoop.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ReservationsController : ControllerBase
    {
        private readonly ApplicationDbContext _db;
        private readonly RabbitMqPublisher _mq;
        private readonly IReservationStateService _reservationStateService;
        private readonly ILogger<ReservationsController> _logger;

        public ReservationsController(
            ApplicationDbContext db,
            RabbitMqPublisher mq,
            IReservationStateService reservationStateService,
            ILogger<ReservationsController> logger)
        {
            _db = db;
            _mq = mq;
            _reservationStateService = reservationStateService;
            _logger = logger;
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
            if (!ModelState.IsValid)
            {
                _logger.LogWarning("Create reservation failed due to invalid model state.");
                return BadRequest(ModelState);
            }

            var userId = GetUserId();
            if (userId == 0)
            {
                _logger.LogWarning("Create reservation failed because user was unauthorized.");
                return Unauthorized();
            }

            _logger.LogInformation(
                "Reservation create attempt by user {UserId} for listing {ListingId}.",
                userId,
                request.ListingId);

            if (request.CheckOut <= request.CheckIn)
            {
                _logger.LogWarning(
                    "Create reservation failed for user {UserId} because check-out was not after check-in.",
                    userId);
                return BadRequest("Check-out must be after check-in.");
            }

            var listing = await _db.Listings.FirstOrDefaultAsync(l => l.Id == request.ListingId && l.IsActive);
            if (listing == null)
            {
                _logger.LogWarning(
                    "Create reservation failed for user {UserId} because listing {ListingId} was not found or inactive.",
                    userId,
                    request.ListingId);
                return NotFound("Listing not found.");
            }

            if (request.Guests <= 0)
            {
                _logger.LogWarning(
                    "Create reservation failed for user {UserId} because guests value {Guests} was invalid.",
                    userId,
                    request.Guests);
                return BadRequest("Guests must be greater than 0.");
            }

            if (request.Guests > listing.MaxGuests)
            {
                _logger.LogWarning(
                    "Create reservation failed for user {UserId} because guests {Guests} exceeded max {MaxGuests} for listing {ListingId}.",
                    userId,
                    request.Guests,
                    listing.MaxGuests,
                    listing.Id);
                return BadRequest($"Maximum allowed guests for this listing is {listing.MaxGuests}.");
            }

            var days = (request.CheckOut - request.CheckIn).Days;
            if (days <= 0)
            {
                _logger.LogWarning(
                    "Create reservation failed for user {UserId} because date range was invalid.",
                    userId);
                return BadRequest("Invalid date range.");
            }

            var totalPrice = days * listing.PricePerNight;

            var overlap = await _db.Reservations.AnyAsync(r =>
                r.PropertyId == listing.Id &&
                (r.StatusId == ReservationStatusIds.Pending || r.StatusId == ReservationStatusIds.Approved) &&
                request.CheckIn < r.CheckOut &&
                request.CheckOut > r.CheckIn);

            if (overlap)
            {
                _logger.LogWarning(
                    "Create reservation failed for user {UserId} because selected dates overlap for listing {ListingId}.",
                    userId,
                    listing.Id);
                return BadRequest("Selected dates are not available.");
            }

            var reservation = new Reservation
            {
                UserId = userId,
                PropertyId = listing.Id,
                CheckIn = request.CheckIn,
                CheckOut = request.CheckOut,
                Guests = request.Guests,
                TotalPrice = totalPrice,
                StatusId = ReservationStatusIds.Pending,
                CreatedAt = DateTime.UtcNow,
                Note = string.IsNullOrWhiteSpace(request.Note) ? null : request.Note.Trim()
            };

            _db.Reservations.Add(reservation);
            await _db.SaveChangesAsync();

            _logger.LogInformation(
                "Reservation created successfully. ReservationId: {ReservationId}, UserId: {UserId}, ListingId: {ListingId}.",
                reservation.Id,
                userId,
                listing.Id);

            return Ok(new { message = "Reservation created (pending approval)." });
        }

        // CLIENT — my reservations
        [HttpGet("my")]
        public async Task<IActionResult> MyReservations()
        {
            var userId = GetUserId();
            if (userId == 0)
            {
                _logger.LogWarning("MyReservations failed because user was unauthorized.");
                return Unauthorized();
            }

            _logger.LogInformation("Loading reservations for user {UserId}.", userId);

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

                    CanPay = r.StatusId == ReservationStatusIds.Approved && !r.IsPaid,
                    CanCancel = r.StatusId == ReservationStatusIds.Pending,

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

            _logger.LogInformation(
                "Loaded {Count} reservations for user {UserId}.",
                data.Count,
                userId);

            return Ok(data);
        }

        // CLIENT — cancel reservation
        [HttpPut("{id:int}/cancel")]
        public async Task<IActionResult> Cancel(int id)
        {
            var userId = GetUserId();
            if (userId == 0)
            {
                _logger.LogWarning("Cancel reservation failed because user was unauthorized.");
                return Unauthorized();
            }

            _logger.LogInformation(
                "Cancel reservation attempt. ReservationId: {ReservationId}, UserId: {UserId}.",
                id,
                userId);

            var r = await _db.Reservations
                .FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId);

            if (r == null)
            {
                _logger.LogWarning(
                    "Cancel reservation failed because reservation {ReservationId} was not found for user {UserId}.",
                    id,
                    userId);
                return NotFound("Reservation not found.");
            }

            var result = await _reservationStateService.ChangeStatusAsync(
                r,
                ReservationStatusIds.Cancelled);

            if (!result.Success)
            {
                _logger.LogWarning(
                    "Cancel reservation failed for reservation {ReservationId}. Reason: {Reason}",
                    id,
                    result.Message);
                return BadRequest(result.Message);
            }

            r.DecisionAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();

            _logger.LogInformation(
                "Reservation {ReservationId} cancelled successfully by user {UserId}.",
                id,
                userId);

            return Ok(new { message = result.Message });
        }

        // ADMIN — pending reservations
        [HttpGet("pending")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Pending()
        {
            var adminId = GetUserId();
            if (adminId == 0)
            {
                _logger.LogWarning("Pending reservations load failed because admin was unauthorized.");
                return Unauthorized();
            }

            _logger.LogInformation("Loading pending reservations for admin {AdminId}.", adminId);

            var data = await _db.Reservations
                .AsNoTracking()
                .Include(r => r.User)
                .Include(r => r.Property)
                .Include(r => r.Status)
                .Where(r => r.StatusId == ReservationStatusIds.Pending)
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

            _logger.LogInformation(
                "Loaded {Count} pending reservations for admin {AdminId}.",
                data.Count,
                adminId);

            return Ok(data);
        }

        // ADMIN — approve
        [HttpPut("{id:int}/approve")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Approve(int id)
        {
            var adminId = GetUserId();
            if (adminId == 0)
            {
                _logger.LogWarning("Approve reservation failed because admin was unauthorized.");
                return Unauthorized();
            }

            _logger.LogInformation(
                "Approve reservation attempt. ReservationId: {ReservationId}, AdminId: {AdminId}.",
                id,
                adminId);

            var r = await _db.Reservations
                .FirstOrDefaultAsync(x => x.Id == id);

            if (r == null)
            {
                _logger.LogWarning(
                    "Approve reservation failed because reservation {ReservationId} was not found.",
                    id);
                return NotFound("Reservation not found.");
            }

            var overlapExists = await _db.Reservations.AnyAsync(x =>
                x.Id != r.Id &&
                x.PropertyId == r.PropertyId &&
                x.StatusId == ReservationStatusIds.Approved &&
                r.CheckIn < x.CheckOut &&
                r.CheckOut > x.CheckIn);

            if (overlapExists)
            {
                _logger.LogWarning(
                    "Approve reservation failed for reservation {ReservationId} because selected dates are no longer available.",
                    id);
                return BadRequest("Selected dates are no longer available.");
            }

            var result = await _reservationStateService.ChangeStatusAsync(
                r,
                ReservationStatusIds.Approved);

            if (!result.Success)
            {
                _logger.LogWarning(
                    "Approve reservation failed for reservation {ReservationId}. Reason: {Reason}",
                    id,
                    result.Message);
                return BadRequest(result.Message);
            }

            r.ApprovedByAdminId = adminId;
            r.DecisionAt = DateTime.UtcNow;

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

            _logger.LogInformation(
                "Reservation {ReservationId} approved successfully by admin {AdminId}.",
                id,
                adminId);

            return Ok(new { message = result.Message });
        }

        // ADMIN — all reservations (optional status)
        [HttpGet("admin")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> All([FromQuery] int? statusId)
        {
            var adminId = GetUserId();
            if (adminId == 0)
            {
                _logger.LogWarning("All reservations load failed because admin was unauthorized.");
                return Unauthorized();
            }

            _logger.LogInformation(
                "Loading all reservations for admin {AdminId} with status filter {StatusId}.",
                adminId,
                statusId);

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

            _logger.LogInformation(
                "Loaded {Count} reservations for admin {AdminId}.",
                data.Count,
                adminId);

            return Ok(data);
        }

        // ADMIN — reject
        [HttpPut("{id:int}/reject")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Reject(int id)
        {
            var adminId = GetUserId();
            if (adminId == 0)
            {
                _logger.LogWarning("Reject reservation failed because admin was unauthorized.");
                return Unauthorized();
            }

            _logger.LogInformation(
                "Reject reservation attempt. ReservationId: {ReservationId}, AdminId: {AdminId}.",
                id,
                adminId);

            var r = await _db.Reservations.FindAsync(id);
            if (r == null)
            {
                _logger.LogWarning(
                    "Reject reservation failed because reservation {ReservationId} was not found.",
                    id);
                return NotFound("Reservation not found.");
            }

            var result = await _reservationStateService.ChangeStatusAsync(
                r,
                ReservationStatusIds.Rejected);

            if (!result.Success)
            {
                _logger.LogWarning(
                    "Reject reservation failed for reservation {ReservationId}. Reason: {Reason}",
                    id,
                    result.Message);
                return BadRequest(result.Message);
            }

            r.ApprovedByAdminId = adminId;
            r.DecisionAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();

            _logger.LogInformation(
                "Reservation {ReservationId} rejected successfully by admin {AdminId}.",
                id,
                adminId);

            return Ok(new { message = result.Message });
        }
    }
}