using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;
using RentLoop.API.Helpers;

namespace RentLoop.API.Controllers
{
    [ApiController]
    [Route("api/availability")]
    [Authorize]
    public class AvailabilityController : ControllerBase
    {
        private readonly ApplicationDbContext _db;

        public AvailabilityController(ApplicationDbContext db)
        {
            _db = db;
        }

        // GET api/availability/12?from=2026-01-01&to=2026-02-01
        [HttpGet("{propertyId:int}")]
        public async Task<IActionResult> Get(int propertyId, [FromQuery] DateTime? from, [FromQuery] DateTime? to)
        {
            var fromDate = from?.Date ?? DateTime.UtcNow.Date;
            var toDate = to?.Date ?? fromDate.AddMonths(6);

            if (toDate <= fromDate)
                return BadRequest("Invalid range.");

            var reservations = await _db.Reservations
                .AsNoTracking()
                .Where(r =>
                    r.PropertyId == propertyId &&
                    (r.StatusId == ReservationStatusIds.Pending ||
                     r.StatusId == ReservationStatusIds.Approved) &&
                    fromDate < r.CheckOut &&
                    toDate > r.CheckIn)
                .Select(r => new { r.CheckIn, r.CheckOut })
                .ToListAsync();

            var bookedDays = new HashSet<DateTime>();

            foreach (var r in reservations)
            {
                var start = r.CheckIn.Date < fromDate ? fromDate : r.CheckIn.Date;
                var end = r.CheckOut.Date > toDate ? toDate : r.CheckOut.Date;

                for (var d = start; d < end; d = d.AddDays(1))
                {
                    bookedDays.Add(d);
                }
            }

            return Ok(bookedDays.OrderBy(d => d).ToList());
        }
    }
}