using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;
using RentLoop.API.Models;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace RentLoop.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize] // mora biti ulogovan korisnik
    public class FavoritesController : ControllerBase
    {
        private readonly ApplicationDbContext _db;

        public FavoritesController(ApplicationDbContext db)
        {
            _db = db;
        }

        // helper: uzmi userId iz JWT tokena (sub claim)
        private int GetUserId()
        {
            var id =
                User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? User.FindFirstValue("sub");

            if (string.IsNullOrWhiteSpace(id))
                throw new Exception("Invalid token: missing user id claim.");

            return int.Parse(id);
        }


        // POST: api/favorites/{listingId}
        // Dodaj listing u favorite
        [HttpPost("{listingId:int}")]
        public async Task<IActionResult> Add(int listingId)
        {
            var userId = GetUserId();

            var listingExists = await _db.Listings.AnyAsync(l => l.Id == listingId && l.IsActive);
            if (!listingExists) return NotFound("Listing not found.");

            var already = await _db.Favorites.AnyAsync(f => f.UserId == userId && f.PropertyId == listingId);
            if (already) return Ok(new { message = "Already in favorites." });

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

        // DELETE: api/favorites/{listingId}
        // Ukloni listing iz favorita
        [HttpDelete("{listingId:int}")]
        public async Task<IActionResult> Remove(int listingId)
        {
            var userId = GetUserId();

            var fav = await _db.Favorites
                .FirstOrDefaultAsync(f => f.UserId == userId && f.PropertyId == listingId);

            if (fav == null) return NotFound("Favorite not found.");

            _db.Favorites.Remove(fav);
            await _db.SaveChangesAsync();

            return Ok(new { message = "Removed from favorites." });
        }

        // GET: api/favorites
        // Lista mojih favorita (za profile/favorites screen)
        [HttpGet]
        public async Task<IActionResult> MyFavorites()
        {
            var userId = GetUserId();

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

        // GET: api/favorites/check/{listingId}
        // Da li je ovaj listing u mojim favoritima?
        [HttpGet("check/{listingId:int}")]
        public async Task<IActionResult> IsFavorite(int listingId)
        {
            var userId = GetUserId();

            var isFav = await _db.Favorites
                .AsNoTracking()
                .AnyAsync(f => f.UserId == userId && f.PropertyId == listingId);

            return Ok(new { listingId, isFavorite = isFav });
        }
    }
}
