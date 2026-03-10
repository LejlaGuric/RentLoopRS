using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;
using RentLoop.API.Models;
using System.Security.Claims;

namespace RentLoop.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class FavoritesController : ControllerBase
    {
        private readonly ApplicationDbContext _db;

        public FavoritesController(ApplicationDbContext db)
        {
            _db = db;
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

        [HttpPost("{listingId:int}")]
        public async Task<IActionResult> Add(int listingId)
        {
            var userId = GetUserId();
            if (userId == 0)
                return Unauthorized();

            var listingExists = await _db.Listings.AnyAsync(l => l.Id == listingId && l.IsActive);
            if (!listingExists)
                return NotFound("Listing not found.");

            var already = await _db.Favorites.AnyAsync(f => f.UserId == userId && f.PropertyId == listingId);
            if (already)
                return Ok(new { message = "Already in favorites." });

            var fav = new Favorite
            {
                UserId = userId,
                PropertyId = listingId,
                CreatedAt = DateTime.UtcNow
            };

            _db.Favorites.Add(fav);
            await _db.SaveChangesAsync();

            return Ok(new { message = "Added to favorites." });
        }

        [HttpDelete("{listingId:int}")]
        public async Task<IActionResult> Remove(int listingId)
        {
            var userId = GetUserId();
            if (userId == 0)
                return Unauthorized();

            var fav = await _db.Favorites
                .FirstOrDefaultAsync(f => f.UserId == userId && f.PropertyId == listingId);

            if (fav == null)
                return NotFound("Favorite not found.");

            _db.Favorites.Remove(fav);
            await _db.SaveChangesAsync();

            return Ok(new { message = "Removed from favorites." });
        }

        [HttpGet]
        public async Task<IActionResult> MyFavorites()
        {
            var userId = GetUserId();
            if (userId == 0)
                return Unauthorized();

            var data = await _db.Favorites
                .AsNoTracking()
                .Where(f => f.UserId == userId)
                .OrderByDescending(f => f.CreatedAt)
                .Select(f => new
                {
                    f.PropertyId,
                    f.CreatedAt,
                    Listing = _db.Listings
                        .Where(l => l.Id == f.PropertyId)
                        .Select(l => new
                        {
                            l.Id,
                            l.Name,
                            l.PricePerNight,
                            City = l.City != null ? l.City.Name : "",
                            RentType = l.RentType != null ? l.RentType.Name : "",
                            CoverUrl = _db.PropertyImages
                                .Where(pi => pi.PropertyId == l.Id && pi.IsCover)
                                .Select(pi => pi.Url)
                                .FirstOrDefault()
                                ?? _db.PropertyImages
                                    .Where(pi => pi.PropertyId == l.Id)
                                    .OrderBy(pi => pi.SortOrder)
                                    .Select(pi => pi.Url)
                                    .FirstOrDefault()
                        })
                        .FirstOrDefault()
                })
                .ToListAsync();

            return Ok(data);
        }

        [HttpGet("check/{listingId:int}")]
        public async Task<IActionResult> IsFavorite(int listingId)
        {
            var userId = GetUserId();
            if (userId == 0)
                return Unauthorized();

            var isFav = await _db.Favorites
                .AsNoTracking()
                .AnyAsync(f => f.UserId == userId && f.PropertyId == listingId);

            return Ok(new { listingId, isFavorite = isFav });
        }
    }
}