using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;
using RentLoop.API.Models;
using System.ComponentModel.DataAnnotations;

namespace RentLoop.API.Controllers
{
    [ApiController]
    [Route("api/lookups")]
    public class LookupsController : ControllerBase
    {
        private readonly ApplicationDbContext _db;

        public LookupsController(ApplicationDbContext db)
        {
            _db = db;
        }

        public class LookupUpsertRequest
        {
            [Required]
            [MaxLength(100)]
            public string Name { get; set; } = "";
        }

        // =========================
        // CITIES
        // =========================

        [HttpGet("cities")]
        [AllowAnonymous]
        public async Task<IActionResult> Cities()
        {
            var data = await _db.Cities
                .AsNoTracking()
                .OrderBy(x => x.Name)
                .Select(x => new { x.Id, x.Name })
                .ToListAsync();

            return Ok(data);
        }

        [HttpPost("cities")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> CreateCity([FromBody] LookupUpsertRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var name = (request.Name ?? "").Trim();
            if (string.IsNullOrWhiteSpace(name))
                return BadRequest("Name is required.");

            var exists = await _db.Cities.AnyAsync(x => x.Name.ToLower() == name.ToLower());
            if (exists)
                return BadRequest("City already exists.");

            var city = new City
            {
                Name = name
            };

            _db.Cities.Add(city);
            await _db.SaveChangesAsync();

            return Ok(new { city.Id, city.Name });
        }

        [HttpPut("cities/{id:int}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> UpdateCity(int id, [FromBody] LookupUpsertRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var name = (request.Name ?? "").Trim();
            if (string.IsNullOrWhiteSpace(name))
                return BadRequest("Name is required.");

            var city = await _db.Cities.FirstOrDefaultAsync(x => x.Id == id);
            if (city == null)
                return NotFound("City not found.");

            var exists = await _db.Cities.AnyAsync(x => x.Id != id && x.Name.ToLower() == name.ToLower());
            if (exists)
                return BadRequest("City already exists.");

            city.Name = name;
            await _db.SaveChangesAsync();

            return Ok(new { city.Id, city.Name });
        }

        [HttpDelete("cities/{id:int}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> DeleteCity(int id)
        {
            var city = await _db.Cities.FirstOrDefaultAsync(x => x.Id == id);
            if (city == null)
                return NotFound("City not found.");

            _db.Cities.Remove(city);

            try
            {
                await _db.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                return Conflict("City cannot be deleted because related records exist.");
            }

            return Ok(new { message = "City deleted." });
        }

        // =========================
        // RENT TYPES
        // =========================

        [HttpGet("rent-types")]
        [AllowAnonymous]
        public async Task<IActionResult> RentTypes()
        {
            var data = await _db.RentTypes
                .AsNoTracking()
                .OrderBy(x => x.Name)
                .Select(x => new { x.Id, x.Name })
                .ToListAsync();

            return Ok(data);
        }

        [HttpPost("rent-types")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> CreateRentType([FromBody] LookupUpsertRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var name = (request.Name ?? "").Trim();
            if (string.IsNullOrWhiteSpace(name))
                return BadRequest("Name is required.");

            var exists = await _db.RentTypes.AnyAsync(x => x.Name.ToLower() == name.ToLower());
            if (exists)
                return BadRequest("Rent type already exists.");

            var rentType = new RentType
            {
                Name = name
            };

            _db.RentTypes.Add(rentType);
            await _db.SaveChangesAsync();

            return Ok(new { rentType.Id, rentType.Name });
        }

        [HttpPut("rent-types/{id:int}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> UpdateRentType(int id, [FromBody] LookupUpsertRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var name = (request.Name ?? "").Trim();
            if (string.IsNullOrWhiteSpace(name))
                return BadRequest("Name is required.");

            var rentType = await _db.RentTypes.FirstOrDefaultAsync(x => x.Id == id);
            if (rentType == null)
                return NotFound("Rent type not found.");

            var exists = await _db.RentTypes.AnyAsync(x => x.Id != id && x.Name.ToLower() == name.ToLower());
            if (exists)
                return BadRequest("Rent type already exists.");

            rentType.Name = name;
            await _db.SaveChangesAsync();

            return Ok(new { rentType.Id, rentType.Name });
        }

        [HttpDelete("rent-types/{id:int}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> DeleteRentType(int id)
        {
            var rentType = await _db.RentTypes.FirstOrDefaultAsync(x => x.Id == id);
            if (rentType == null)
                return NotFound("Rent type not found.");

            _db.RentTypes.Remove(rentType);

            try
            {
                await _db.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                return Conflict("Rent type cannot be deleted because related records exist.");
            }

            return Ok(new { message = "Rent type deleted." });
        }

        // =========================
        // AMENITIES
        // =========================

        [HttpGet("amenities")]
        [AllowAnonymous]
        public async Task<IActionResult> Amenities()
        {
            var data = await _db.Amenities
                .AsNoTracking()
                .OrderBy(x => x.Name)
                .Select(x => new { x.Id, x.Name })
                .ToListAsync();

            return Ok(data);
        }

        [HttpPost("amenities")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> CreateAmenity([FromBody] LookupUpsertRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var name = (request.Name ?? "").Trim();
            if (string.IsNullOrWhiteSpace(name))
                return BadRequest("Name is required.");

            var exists = await _db.Amenities.AnyAsync(x => x.Name.ToLower() == name.ToLower());
            if (exists)
                return BadRequest("Amenity already exists.");

            var amenity = new Amenity
            {
                Name = name
            };

            _db.Amenities.Add(amenity);
            await _db.SaveChangesAsync();

            return Ok(new { amenity.Id, amenity.Name });
        }

        [HttpPut("amenities/{id:int}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> UpdateAmenity(int id, [FromBody] LookupUpsertRequest request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var name = (request.Name ?? "").Trim();
            if (string.IsNullOrWhiteSpace(name))
                return BadRequest("Name is required.");

            var amenity = await _db.Amenities.FirstOrDefaultAsync(x => x.Id == id);
            if (amenity == null)
                return NotFound("Amenity not found.");

            var exists = await _db.Amenities.AnyAsync(x => x.Id != id && x.Name.ToLower() == name.ToLower());
            if (exists)
                return BadRequest("Amenity already exists.");

            amenity.Name = name;
            await _db.SaveChangesAsync();

            return Ok(new { amenity.Id, amenity.Name });
        }

        [HttpDelete("amenities/{id:int}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> DeleteAmenity(int id)
        {
            var amenity = await _db.Amenities.FirstOrDefaultAsync(x => x.Id == id);
            if (amenity == null)
                return NotFound("Amenity not found.");

            _db.Amenities.Remove(amenity);

            try
            {
                await _db.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                return Conflict("Amenity cannot be deleted because related records exist.");
            }

            return Ok(new { message = "Amenity deleted." });
        }
    }
}