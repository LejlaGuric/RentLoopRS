using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;
using RentLoop.API.DTOs.Listing;
using RentLoop.API.DTOs;
using RentLoop.API.Models;
using System.Security.Claims;

namespace RentLoop.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ListingsController : ControllerBase
    {
        private readonly ApplicationDbContext _db;
        private readonly IWebHostEnvironment _env;

        public ListingsController(ApplicationDbContext db, IWebHostEnvironment env)
        {
            _db = db;
            _env = env;
        }

        // -------------------- HELPERS --------------------
        private int? GetUserIdOrNull()
        {
            var raw = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (int.TryParse(raw, out var id)) return id;
            return null;
        }

       
        [HttpGet]
        public async Task<IActionResult> GetAll(
            [FromQuery] int? cityId,
            [FromQuery] int? rentTypeId,
            [FromQuery] decimal? minPrice,
            [FromQuery] decimal? maxPrice,
            [FromQuery] int? rooms,
            [FromQuery] int? guests,
            [FromQuery] string? sort,
            [FromQuery] string? q
        )
        {
            var query = _db.Listings
                .AsNoTracking()
                .Include(l => l.City)
                .Include(l => l.RentType)
                .Where(l => l.IsActive)
                .AsQueryable();

            // FILTERI
            if (cityId.HasValue) query = query.Where(l => l.CityId == cityId.Value);
            if (rentTypeId.HasValue) query = query.Where(l => l.RentTypeId == rentTypeId.Value);
            if (minPrice.HasValue) query = query.Where(l => l.PricePerNight >= minPrice.Value);
            if (maxPrice.HasValue) query = query.Where(l => l.PricePerNight <= maxPrice.Value);
            if (rooms.HasValue) query = query.Where(l => l.RoomsCount == rooms.Value);
            if (guests.HasValue) query = query.Where(l => l.MaxGuests >= guests.Value);

            // ✅ SEARCH PO NAZIVU
            if (!string.IsNullOrWhiteSpace(q))
            {
                var term = q.Trim();
                query = query.Where(l => EF.Functions.Like(l.Name, $"%{term}%"));
            }

            // SORTIRANJE
            sort = (sort ?? "newest").ToLower();
            query = sort switch
            {
                "priceasc" => query.OrderBy(l => l.PricePerNight),
                "pricedesc" => query.OrderByDescending(l => l.PricePerNight),
                "distanceasc" => query.OrderBy(l => l.DistanceToCenterKm),
                _ => query.OrderByDescending(l => l.CreatedAt)
            };

            var data = await query
                .Select(l => new
                {
                    l.Id,
                    l.Name,
                    l.PricePerNight,
                    City = l.City != null ? l.City.Name : "",
                    RentType = l.RentType != null ? l.RentType.Name : "",
                    l.RoomsCount,
                    l.MaxGuests,
                    l.DistanceToCenterKm,
                    l.HasWifi,
                    l.HasAirConditioning,
                    l.PetsAllowed,
                    l.IsActive,
                    l.CreatedAt,

                    CoverUrl = _db.PropertyImages
                        .Where(pi => pi.PropertyId == l.Id && pi.IsCover)
                        .Select(pi => pi.Url)
                        .FirstOrDefault()
                        ?? _db.PropertyImages
                            .Where(pi => pi.PropertyId == l.Id)
                            .OrderBy(pi => pi.SortOrder)
                            .Select(pi => pi.Url)
                            .FirstOrDefault(),

                    AvgRating = _db.Reviews
                        .Where(rv => rv.PropertyId == l.Id)
                        .Select(rv => (double?)rv.Rating)
                        .Average() ?? 0,

                    ReviewsCount = _db.Reviews.Count(rv => rv.PropertyId == l.Id)
                })
                .ToListAsync();

            return Ok(data);
        }


        // -------------------- RECOMMENDATIONS --------------------

        // ✅ GET: api/listings/popular?take=15
        [HttpGet("popular")]
        public async Task<IActionResult> Popular([FromQuery] int take = 15)
        {
            take = Math.Clamp(take, 1, 50);

            var fromViews = DateTime.UtcNow.AddDays(-7);
            var fromRes = DateTime.UtcNow.AddDays(-30);

            var views7d = await _db.ListingViews
                .AsNoTracking()
                .Where(v => v.ViewedAt >= fromViews)
                .GroupBy(v => v.ListingId)
                .Select(g => new { ListingId = g.Key, Cnt = g.Count() })
                .ToDictionaryAsync(x => x.ListingId, x => x.Cnt);

            var res30d = await _db.Reservations
                .AsNoTracking()
                .Where(r => r.CreatedAt >= fromRes)
                .GroupBy(r => r.PropertyId)
                .Select(g => new { ListingId = g.Key, Cnt = g.Count() })
                .ToDictionaryAsync(x => x.ListingId, x => x.Cnt);

            var listings = await _db.Listings
                .AsNoTracking()
                .Include(l => l.City)
                .Include(l => l.RentType)
                .Where(l => l.IsActive)
                .OrderByDescending(l => l.CreatedAt)
                .Take(250)
                .Select(l => new
                {
                    l.Id,
                    l.Name,
                    l.PricePerNight,
                    City = l.City != null ? l.City.Name : "",
                    RentType = l.RentType != null ? l.RentType.Name : "",
                    l.RoomsCount,
                    l.MaxGuests,
                    l.DistanceToCenterKm,
                    l.CreatedAt,

                    CoverUrl = _db.PropertyImages
                        .Where(pi => pi.PropertyId == l.Id && pi.IsCover)
                        .Select(pi => pi.Url)
                        .FirstOrDefault()
                        ?? _db.PropertyImages
                            .Where(pi => pi.PropertyId == l.Id)
                            .OrderBy(pi => pi.SortOrder)
                            .Select(pi => pi.Url)
                            .FirstOrDefault(),

                    AvgRating = _db.Reviews
                        .Where(rv => rv.PropertyId == l.Id)
                        .Select(rv => (double?)rv.Rating)
                        .Average() ?? 0,

                    ReviewsCount = _db.Reviews.Count(rv => rv.PropertyId == l.Id)
                })
                .ToListAsync();

            int PopularScore(dynamic x)
            {
                int score = 0;
                if (views7d.TryGetValue((int)x.Id, out var vCnt)) score += Math.Min(15, vCnt / 2);
                if (res30d.TryGetValue((int)x.Id, out var rCnt)) score += Math.Min(30, rCnt * 3);
                score += (int)Math.Min(10, x.AvgRating * 2);
                score += (int)Math.Min(5, x.ReviewsCount / 10);
                return score;
            }

            var ranked = listings
                .Select(x => new
                {
                    x.Id,
                    x.Name,
                    x.PricePerNight,
                    x.City,
                    x.RentType,
                    x.RoomsCount,
                    x.MaxGuests,
                    x.DistanceToCenterKm,
                    x.CoverUrl,
                    x.AvgRating,
                    x.ReviewsCount,
                    Score = PopularScore(x),
                    x.CreatedAt
                })
                .OrderByDescending(x => x.Score)
                .ThenByDescending(x => x.CreatedAt)
                .Take(take)
                .ToList();

            return Ok(ranked);
        }

        // ✅ GET: api/listings/recommended?take=15
        [HttpGet("recommended")]
        [Authorize]
        public async Task<IActionResult> Recommended([FromQuery] int take = 15)
        {
            take = Math.Clamp(take, 1, 50);

            var userId = GetUserIdOrNull();
            if (!userId.HasValue) return Unauthorized();

            // 1) Zadnja pretraga
            var lastSearch = await _db.SearchHistory
                .AsNoTracking()
                .Where(s => s.UserId == userId.Value)
                .OrderByDescending(s => s.SearchedAt)
                .FirstOrDefaultAsync();

            // 2) Zadnjih 10 views
            var recentViewedIds = await _db.ListingViews
                .AsNoTracking()
                .Where(v => v.UserId == userId.Value)
                .OrderByDescending(v => v.ViewedAt)
                .Select(v => v.ListingId)
                .Distinct()
                .Take(10)
                .ToListAsync();

            // 3) Zadnjih 5 rezervacija
            var recentReservedIds = await _db.Reservations
                .AsNoTracking()
                .Where(r => r.UserId == userId.Value)
                .OrderByDescending(r => r.CreatedAt)
                .Select(r => r.PropertyId)
                .Distinct()
                .Take(5)
                .ToListAsync();

            // Ne preporučuj ono što je user već rezervisao
            var exclude = recentReservedIds;

            // 4) Popularnost mape
            var fromViews = DateTime.UtcNow.AddDays(-7);
            var fromRes = DateTime.UtcNow.AddDays(-30);

            var views7d = await _db.ListingViews
                .AsNoTracking()
                .Where(v => v.ViewedAt >= fromViews)
                .GroupBy(v => v.ListingId)
                .Select(g => new { ListingId = g.Key, Cnt = g.Count() })
                .ToDictionaryAsync(x => x.ListingId, x => x.Cnt);

            var res30d = await _db.Reservations
                .AsNoTracking()
                .Where(r => r.CreatedAt >= fromRes)
                .GroupBy(r => r.PropertyId)
                .Select(g => new { ListingId = g.Key, Cnt = g.Count() })
                .ToDictionaryAsync(x => x.ListingId, x => x.Cnt);

            // 5) Listing profili iz historije (za “sličnost”)
            var historyIds = recentViewedIds.Concat(recentReservedIds).Distinct().ToList();

            var historyListings = await _db.Listings
                .AsNoTracking()
                .Where(l => historyIds.Contains(l.Id))
                .Select(l => new { l.Id, l.CityId, l.RentTypeId, l.PricePerNight, l.RoomsCount })
                .ToListAsync();

            // 6) Kandidati (limit)
            var baseQuery = _db.Listings
                .AsNoTracking()
                .Include(l => l.City)
                .Include(l => l.RentType)
                .Where(l => l.IsActive && !exclude.Contains(l.Id));

            // ako ima zadnja pretraga, favorizuj taj grad (ali i dalje uzmi newest limit)
            if (lastSearch?.CityId != null)
            {
                // Ne filtriramo strogo samo taj grad da ne ispadne prazno, samo ostavljamo kandidatima šansu
                // Kandidati su newest 250, scoring će pogurati grad
            }

            var candidates = await baseQuery
                .OrderByDescending(l => l.CreatedAt)
                .Take(250)
                .Select(l => new
                {
                    l.Id,
                    l.Name,
                    l.PricePerNight,
                    City = l.City != null ? l.City.Name : "",
                    RentType = l.RentType != null ? l.RentType.Name : "",
                    l.CityId,
                    l.RentTypeId,
                    l.RoomsCount,
                    l.MaxGuests,
                    l.DistanceToCenterKm,
                    l.CreatedAt,

                    CoverUrl = _db.PropertyImages
                        .Where(pi => pi.PropertyId == l.Id && pi.IsCover)
                        .Select(pi => pi.Url)
                        .FirstOrDefault()
                        ?? _db.PropertyImages
                            .Where(pi => pi.PropertyId == l.Id)
                            .OrderBy(pi => pi.SortOrder)
                            .Select(pi => pi.Url)
                            .FirstOrDefault(),

                    AvgRating = _db.Reviews
                        .Where(rv => rv.PropertyId == l.Id)
                        .Select(rv => (double?)rv.Rating)
                        .Average() ?? 0,

                    ReviewsCount = _db.Reviews.Count(rv => rv.PropertyId == l.Id)
                })
                .ToListAsync();

            int Score(dynamic c)
            {
                int score = 0;

                // A) Pretraga korisnika
                if (lastSearch != null)
                {
                    if (lastSearch.CityId.HasValue && c.CityId == lastSearch.CityId.Value) score += 40;
                    if (lastSearch.RentTypeId.HasValue && c.RentTypeId == lastSearch.RentTypeId.Value) score += 25;

                    if (lastSearch.MinPrice.HasValue && c.PricePerNight >= lastSearch.MinPrice.Value) score += 10;
                    if (lastSearch.MaxPrice.HasValue && c.PricePerNight <= lastSearch.MaxPrice.Value) score += 10;

                    if (lastSearch.RoomsCount.HasValue && c.RoomsCount == lastSearch.RoomsCount.Value) score += 10;
                    if (lastSearch.Guests.HasValue && c.MaxGuests >= lastSearch.Guests.Value) score += 10;

                    // Sort signal (mali boost)
                    if (!string.IsNullOrWhiteSpace(lastSearch.Sort))
                    {
                        var s = lastSearch.Sort!.ToLower();
                        if (s == "priceasc") score += 2;      // korisnik voli niže cijene
                        if (s == "pricedesc") score += 1;     // korisnik voli premium
                        if (s == "distanceasc" && c.DistanceToCenterKm <= 2) score += 2;
                    }
                }

                // B) Prethodne rezervacije / pregledi (sličnost)
                foreach (var h in historyListings)
                {
                    if (c.CityId == h.CityId) score += 6;
                    if (c.RentTypeId == h.RentTypeId) score += 5;

                    var lower = h.PricePerNight * 0.8m;
                    var upper = h.PricePerNight * 1.2m;
                    if (c.PricePerNight >= lower && c.PricePerNight <= upper) score += 4;

                    if (c.RoomsCount == h.RoomsCount) score += 2;
                }

                // C) Popularnost
                if (views7d.TryGetValue((int)c.Id, out var vCnt)) score += Math.Min(10, vCnt / 3);
                if (res30d.TryGetValue((int)c.Id, out var rCnt)) score += Math.Min(15, rCnt * 2);

                score += (int)Math.Min(10, c.AvgRating * 2);
                score += (int)Math.Min(5, c.ReviewsCount / 10);

                return score;
            }

            var ranked = candidates
                .Select(x => new
                {
                    x.Id,
                    x.Name,
                    x.PricePerNight,
                    x.City,
                    x.RentType,
                    x.RoomsCount,
                    x.MaxGuests,
                    x.DistanceToCenterKm,
                    x.CoverUrl,
                    x.AvgRating,
                    x.ReviewsCount,
                    Score = Score(x),
                    x.CreatedAt
                })
                .OrderByDescending(x => x.Score)
                .ThenByDescending(x => x.CreatedAt)
                .Take(take)
                .ToList();

            // fallback ako nema historije/signala
            if (ranked.Count == 0)
                return await Popular(take);

            return Ok(ranked);
        }

        // ✅ POST: api/listings/{id}/view
        [HttpPost("{id:int}/view")]
        [Authorize]
        public async Task<IActionResult> LogView(int id)
        {
            var userId = GetUserIdOrNull();
            if (!userId.HasValue) return Unauthorized();

            var exists = await _db.Listings.AnyAsync(l => l.Id == id && l.IsActive);
            if (!exists) return NotFound("Listing not found.");

            _db.ListingViews.Add(new ListingView
            {
                UserId = userId.Value,
                ListingId = id,
                ViewedAt = DateTime.UtcNow
            });

            await _db.SaveChangesAsync();
            return Ok(new { message = "View logged." });
        }

        // -------------------- CREATE LISTING (ADMIN) --------------------

        public class ListingCreateFormDataRequest
        {
            public string Name { get; set; } = "";
            public string? Description { get; set; }
            public string? Address { get; set; }

            public int CityId { get; set; }
            public int RentTypeId { get; set; }

            public decimal PricePerNight { get; set; }
            public int RoomsCount { get; set; }
            public int MaxGuests { get; set; }
            public decimal DistanceToCenterKm { get; set; }

            public bool HasWifi { get; set; }
            public bool HasAirConditioning { get; set; }
            public bool PetsAllowed { get; set; }

            public string? AmenityIds { get; set; }

            public int CoverIndex { get; set; } = 0;

            public List<IFormFile> Images { get; set; } = new();
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> Create([FromForm] ListingCreateFormDataRequest req)
        {
            if (string.IsNullOrWhiteSpace(req.Name))
                return BadRequest("Name is required.");

            if (req.PricePerNight <= 0)
                return BadRequest("PricePerNight must be greater than 0.");

            var cityExists = await _db.Cities.AnyAsync(c => c.Id == req.CityId);
            if (!cityExists) return BadRequest("CityId is invalid.");

            var rentTypeExists = await _db.RentTypes.AnyAsync(r => r.Id == req.RentTypeId);
            if (!rentTypeExists) return BadRequest("RentTypeId is invalid.");

            if (req.Images == null || req.Images.Count == 0)
                return BadRequest("Dodaj bar jednu sliku (Images).");

            if (req.CoverIndex < 0 || req.CoverIndex >= req.Images.Count)
                req.CoverIndex = 0;

            var amenityIds = new List<int>();
            if (!string.IsNullOrWhiteSpace(req.AmenityIds))
            {
                try
                {
                    amenityIds = System.Text.Json.JsonSerializer.Deserialize<List<int>>(req.AmenityIds!) ?? new();
                }
                catch
                {
                    return BadRequest("AmenityIds must be valid JSON, e.g. [1,2,3].");
                }
            }

            var listing = new Listing
            {
                Name = req.Name.Trim(),
                Description = req.Description ?? "",
                Address = req.Address ?? "",
                CityId = req.CityId,
                RentTypeId = req.RentTypeId,
                PricePerNight = req.PricePerNight / 10,
                RoomsCount = req.RoomsCount,
                MaxGuests = req.MaxGuests,
                DistanceToCenterKm = req.DistanceToCenterKm,
                HasWifi = req.HasWifi,
                HasAirConditioning = req.HasAirConditioning,
                PetsAllowed = req.PetsAllowed,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            _db.Listings.Add(listing);
            await _db.SaveChangesAsync();

            var uploadsRoot = Path.Combine(_env.WebRootPath, "uploads", "listings", listing.Id.ToString());
            Directory.CreateDirectory(uploadsRoot);

            var allowedExt = new[] { ".jpg", ".jpeg", ".png", ".webp" };

            for (int i = 0; i < req.Images.Count; i++)
            {
                var file = req.Images[i];
                if (file.Length == 0) continue;

                var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
                if (!allowedExt.Contains(ext))
                    return BadRequest("Dozvoljeni formati slika su: jpg, jpeg, png, webp.");

                var fileName = $"{Guid.NewGuid()}{ext}";
                var filePath = Path.Combine(uploadsRoot, fileName);

                using (var stream = System.IO.File.Create(filePath))
                {
                    await file.CopyToAsync(stream);
                }

                var url = $"/uploads/listings/{listing.Id}/{fileName}";

                _db.PropertyImages.Add(new PropertyImage
                {
                    PropertyId = listing.Id,
                    Url = url,
                    IsCover = (i == req.CoverIndex),
                    SortOrder = i
                });
            }

            await _db.SaveChangesAsync();

            if (amenityIds.Count > 0)
            {
                var distinct = amenityIds.Distinct().ToList();

                var existing = await _db.Amenities
                    .Where(a => distinct.Contains(a.Id))
                    .Select(a => a.Id)
                    .ToListAsync();

                foreach (var amenityId in existing)
                {
                    _db.PropertyAmenities.Add(new PropertyAmenity
                    {
                        PropertyId = listing.Id,
                        AmenityId = amenityId
                    });
                }

                await _db.SaveChangesAsync();
            }

            return CreatedAtAction(nameof(GetById), new { id = listing.Id }, new
            {
                listing.Id,
                listing.Name,
                listing.PricePerNight
            });
        }

        // -------------------- GET BY ID --------------------

        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetById(int id)
        {
            var listing = await _db.Listings
                .AsNoTracking()
                .Include(l => l.City)
                .Include(l => l.RentType)
                .Where(l => l.Id == id)
                .Select(l => new
                {
                    l.Id,
                    l.Name,
                    l.Description,
                    l.Address,
                    l.PricePerNight,
                    l.RoomsCount,
                    l.MaxGuests,
                    l.DistanceToCenterKm,
                    l.HasWifi,
                    l.HasAirConditioning,
                    l.PetsAllowed,
                    City = l.City != null ? l.City.Name : "",
                    RentType = l.RentType != null ? l.RentType.Name : "",
                    l.IsActive,
                    l.CreatedAt,
                    Images = _db.PropertyImages
                        .Where(i => i.PropertyId == l.Id)
                        .OrderByDescending(i => i.IsCover)
                        .ThenBy(i => i.SortOrder)
                        .Select(i => new { i.Id, i.Url, i.IsCover, i.SortOrder })
                        .ToList(),
                    AllAmenities = _db.Amenities
                        .OrderBy(a => a.Name)
                        .Select(a => a.Name)
                        .ToList(),

                    SelectedAmenities = _db.PropertyAmenities
                        .Where(pa => pa.PropertyId == l.Id)
                        .Select(pa => pa.Amenity.Name)
                        .ToList(),
                })
                .FirstOrDefaultAsync();

            if (listing == null)
                return NotFound("Listing not found.");

            return Ok(listing);
        }

        // -------------------- IMAGES --------------------

        [HttpGet("{id:int}/images")]
        public async Task<IActionResult> GetImages(int id)
        {
            var exists = await _db.Listings.AnyAsync(l => l.Id == id);
            if (!exists) return NotFound("Listing not found.");

            var images = await _db.PropertyImages
                .AsNoTracking()
                .Where(i => i.PropertyId == id)
                .OrderByDescending(i => i.IsCover)
                .ThenBy(i => i.SortOrder)
                .Select(i => new
                {
                    i.Id,
                    i.Url,
                    i.IsCover,
                    i.SortOrder
                })
                .ToListAsync();

            return Ok(images);
        }

        [HttpPost("{id:int}/images")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> AddImage(int id, [FromBody] ListingImageCreateRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Url))
                return BadRequest("Url is required.");

            var listingExists = await _db.Listings.AnyAsync(l => l.Id == id);
            if (!listingExists) return NotFound("Listing not found.");

            if (request.IsCover)
            {
                var currentCovers = await _db.PropertyImages
                    .Where(x => x.PropertyId == id && x.IsCover)
                    .ToListAsync();

                foreach (var img in currentCovers)
                    img.IsCover = false;
            }

            var image = new PropertyImage
            {
                PropertyId = id,
                Url = request.Url,
                IsCover = request.IsCover,
                SortOrder = request.SortOrder
            };

            _db.PropertyImages.Add(image);
            await _db.SaveChangesAsync();

            return Ok(new
            {
                image.Id,
                image.PropertyId,
                image.Url,
                image.IsCover,
                image.SortOrder
            });
        }

        // -------------------- AVAILABILITY --------------------

        [HttpGet("{id:int}/availability")]
        public async Task<IActionResult> Availability(int id, [FromQuery] DateTime from, [FromQuery] DateTime to)
        {
            if (to <= from) return BadRequest("Invalid range.");

            var exists = await _db.Listings.AnyAsync(l => l.Id == id && l.IsActive);
            if (!exists) return NotFound("Listing not found.");

            var bookedDays = await _db.PropertyAvailability
                .AsNoTracking()
                .Where(a => a.PropertyId == id && a.Date >= from.Date && a.Date < to.Date && a.IsBooked)
                .OrderBy(a => a.Date)
                .Select(a => a.Date)
                .ToListAsync();

            return Ok(bookedDays);
        }
    }
}
