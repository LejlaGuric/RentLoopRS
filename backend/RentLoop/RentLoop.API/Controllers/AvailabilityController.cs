using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;

namespace RentLoop.API.Controllers
{
    [ApiController]
    [Route("api/availability")]
    [Authorize] // dovoljno da je ulogovan
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
            var q = _db.PropertyAvailability
                .AsNoTracking()
                .Where(x => x.PropertyId == propertyId && x.IsBooked);

            if (from.HasValue) q = q.Where(x => x.Date >= from.Value.Date);
            if (to.HasValue) q = q.Where(x => x.Date < to.Value.Date); // to je exclusive

            var dates = await q
                .OrderBy(x => x.Date)
                .Select(x => x.Date)
                .ToListAsync();

            return Ok(dates);
        }
    }
}
