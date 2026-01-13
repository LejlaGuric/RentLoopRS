using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;

namespace RentLoop.API.Controllers
{
    [ApiController]
    [Route("api/lookups")]
    public class LookupsController : ControllerBase
    {
        private readonly ApplicationDbContext _db;
        public LookupsController(ApplicationDbContext db) => _db = db;

        [HttpGet("cities")]
        public async Task<IActionResult> Cities()
            => Ok(await _db.Cities.AsNoTracking().OrderBy(x => x.Name)
                .Select(x => new { x.Id, x.Name }).ToListAsync());

        [HttpGet("rent-types")]
        public async Task<IActionResult> RentTypes()
            => Ok(await _db.RentTypes.AsNoTracking().OrderBy(x => x.Name)
                .Select(x => new { x.Id, x.Name }).ToListAsync());

        [HttpGet("amenities")]
        public async Task<IActionResult> Amenities()
            => Ok(await _db.Amenities.AsNoTracking().OrderBy(x => x.Name)
                .Select(x => new { x.Id, x.Name }).ToListAsync());
    }
}
