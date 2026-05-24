using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RentLoop.API.Data;
using RentLoop.API.DTOs.Listing;
using RentLoop.API.DTOs;
using RentLoop.API.Models;
using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using RentLoop.API.Helpers;
using RentLoop.API.DTOs.Common;

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

        private class ListingScoreItem
        {
            public int Id { get; set; }
            public string Name { get; set; } = "";
            public decimal PricePerNight { get; set; }
            public string City { get; set; } = "";
            public string RentType { get; set; } = "";
            public int CityId { get; set; }
            public int RentTypeId { get; set; }
            public int RoomsCount { get; set; }
            public int MaxGuests { get; set; }
            public decimal DistanceToCenterKm { get; set; }
            public string? CoverUrl { get; set; }
            public double AvgRating { get; set; }
            public int ReviewsCount { get; set; }
            public DateTime CreatedAt { get; set; }
        }

        private class ListingHistoryProfile
        {
            public int Id { get; set; }
            public int CityId { get; set; }
            public int RentTypeId { get; set; }
            public decimal PricePerNight { get; set; }
            public int RoomsCount { get; set; }
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
            [FromQuery] string? q,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20
        )
        {
            page = Math.Max(page, 1);
            pageSize = Math.Clamp(pageSize, 1, 50);

            var query = _db.Listings
                .AsNoTracking()
                .Include(l => l.City)
                .Include(l => l.RentType)
                .Where(l => l.IsActive)
                .AsQueryable();

            if (cityId.HasValue) query = query.Where(l => l.CityId == cityId.Value);
            if (rentTypeId.HasValue) query = query.Where(l => l.RentTypeId == rentTypeId.Value);
            if (minPrice.HasValue) query = query.Where(l => l.PricePerNight >= minPrice.Value);
            if (maxPrice.HasValue) query = query.Where(l => l.PricePerNight <= maxPrice.Value);
            if (rooms.HasValue) query = query.Where(l => l.RoomsCount == rooms.Value);
            if (guests.HasValue) query = query.Where(l => l.MaxGuests >= guests.Value);

            if (!string.IsNullOrWhiteSpace(q))
            {
                var term = q.Trim();
                query = query.Where(l => EF.Functions.Like(l.Name, $"%{term}%"));
            }

            sort = (sort ?? "newest").ToLower();
            query = sort switch
            {
                "priceasc" => query.OrderBy(l => l.PricePerNight),
                "pricedesc" => query.OrderByDescending(l => l.PricePerNight),
                "distanceasc" => query.OrderBy(l => l.DistanceToCenterKm),
                _ => query.OrderByDescending(l => l.CreatedAt)
            };

            var totalCount = await query.CountAsync();

            var data = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
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

            return Ok(new PagedResponse<object>
            {
                Page = page,
                PageSize = pageSize,
                TotalCount = totalCount,
                Items = data.Cast<object>().ToList()
            });
        }

        // -------------------- RECOMMENDATIONS --------------------

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
                .Select(l => new ListingScoreItem
                {
                    Id = l.Id,
                    Name = l.Name,
                    PricePerNight = l.PricePerNight,
                    City = l.City != null ? l.City.Name : "",
                    RentType = l.RentType != null ? l.RentType.Name : "",
                    CityId = l.CityId,
                    RentTypeId = l.RentTypeId,
                    RoomsCount = l.RoomsCount,
                    MaxGuests = l.MaxGuests,
                    DistanceToCenterKm = l.DistanceToCenterKm,
                    CreatedAt = l.CreatedAt,

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

            int PopularScore(ListingScoreItem x)
            {
                int score = 0;
                if (views7d.TryGetValue(x.Id, out var vCnt)) score += Math.Min(15, vCnt / 2);
                if (res30d.TryGetValue(x.Id, out var rCnt)) score += Math.Min(30, rCnt * 3);
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

            return Ok(new PagedResponse<object>
            {
                Page = 1,
                PageSize = take,
                TotalCount = ranked.Count,
                Items = ranked.Cast<object>().ToList()
            });
        }

        [HttpGet("recommended")]
        [Authorize]
        public async Task<IActionResult> Recommended([FromQuery] int take = 15)
        {
            take = Math.Clamp(take, 1, 50);

            var userId = GetUserIdOrNull();
            if (!userId.HasValue) return Unauthorized();

            var recentViewedIds = await _db.ListingViews
                .AsNoTracking()
                .Where(v => v.UserId == userId.Value)
                .OrderByDescending(v => v.ViewedAt)
                .Select(v => v.ListingId)
                .Distinct()
                .Take(10)
                .ToListAsync();

            var recentReservedIds = await _db.Reservations
                .AsNoTracking()
                .Where(r => r.UserId == userId.Value)
                .OrderByDescending(r => r.CreatedAt)
                .Select(r => r.PropertyId)
                .Distinct()
                .Take(5)
                .ToListAsync();

            var exclude = recentReservedIds;

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

            var historyIds = recentViewedIds.Concat(recentReservedIds).Distinct().ToList();

            var historyListings = await _db.Listings
                .AsNoTracking()
                .Where(l => historyIds.Contains(l.Id))
                .Select(l => new ListingHistoryProfile
                {
                    Id = l.Id,
                    CityId = l.CityId,
                    RentTypeId = l.RentTypeId,
                    PricePerNight = l.PricePerNight,
                    RoomsCount = l.RoomsCount
                })
                .ToListAsync();

            var baseQuery = _db.Listings
                .AsNoTracking()
                .Include(l => l.City)
                .Include(l => l.RentType)
                .Where(l => l.IsActive && !exclude.Contains(l.Id));

            var candidates = await baseQuery
                .OrderByDescending(l => l.CreatedAt)
                .Take(250)
                .Select(l => new ListingScoreItem
                {
                    Id = l.Id,
                    Name = l.Name,
                    PricePerNight = l.PricePerNight,
                    City = l.City != null ? l.City.Name : "",
                    RentType = l.RentType != null ? l.RentType.Name : "",
                    CityId = l.CityId,
                    RentTypeId = l.RentTypeId,
                    RoomsCount = l.RoomsCount,
                    MaxGuests = l.MaxGuests,
                    DistanceToCenterKm = l.DistanceToCenterKm,
                    CreatedAt = l.CreatedAt,

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

            int Score(ListingScoreItem c)
            {
                int score = 0;

                foreach (var h in historyListings)
                {
                    if (c.CityId == h.CityId) score += 6;
                    if (c.RentTypeId == h.RentTypeId) score += 5;

                    var lower = h.PricePerNight * 0.8m;
                    var upper = h.PricePerNight * 1.2m;
                    if (c.PricePerNight >= lower && c.PricePerNight <= upper) score += 4;

                    if (c.RoomsCount == h.RoomsCount) score += 2;
                }

                if (views7d.TryGetValue(c.Id, out var vCnt)) score += Math.Min(10, vCnt / 3);
                if (res30d.TryGetValue(c.Id, out var rCnt)) score += Math.Min(15, rCnt * 2);

                score += (int)Math.Min(10, c.AvgRating * 2);
                score += (int)Math.Min(5, c.ReviewsCount / 10);

                return score;
            }

            string BuildReason(ListingScoreItem c)
            {
                var reasons = new List<string>();

                foreach (var h in historyListings)
                {
                    if (c.CityId == h.CityId)
                        reasons.Add("nalazi se u gradu koji ste ranije pregledali");

                    if (c.RentTypeId == h.RentTypeId)
                        reasons.Add("ima isti tip smještaja kao oglasi koji su vas zanimali");

                    var lower = h.PricePerNight * 0.8m;
                    var upper = h.PricePerNight * 1.2m;

                    if (c.PricePerNight >= lower && c.PricePerNight <= upper)
                        reasons.Add("cijena je slična cijenama oglasa koje ste pregledali");

                    if (c.RoomsCount == h.RoomsCount)
                        reasons.Add("ima sličan broj soba kao prethodno pregledani oglasi");
                }

                if (views7d.TryGetValue(c.Id, out var vCnt) && vCnt > 0)
                    reasons.Add("ovaj oglas je često pregledan u zadnjih 7 dana");

                if (res30d.TryGetValue(c.Id, out var rCnt) && rCnt > 0)
                    reasons.Add("ovaj oglas je rezervisan u zadnjih 30 dana");

                if (c.AvgRating >= 4)
                    reasons.Add("ima visoku prosječnu ocjenu korisnika");

                if (c.ReviewsCount > 0)
                    reasons.Add("ima recenzije drugih korisnika");

                if (reasons.Count == 0)
                    return "Preporučeno na osnovu popularnosti.";

                return "Preporučujemo jer " + string.Join(", ", reasons.Distinct().Take(3)) + ".";
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
                    Reason = BuildReason(x),
                    x.CreatedAt
                })
                .OrderByDescending(x => x.Score)
                .ThenByDescending(x => x.CreatedAt)
                .Take(take)
                .ToList();

            if (ranked.Count == 0)
                return await Popular(take);

            return Ok(new PagedResponse<object>
            {
                Page = 1,
                PageSize = take,
                TotalCount = ranked.Count,
                Items = ranked.Cast<object>().ToList()
            });
        }

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
            [Required]
            [MaxLength(100)]
            public string Name { get; set; } = "";

            [MaxLength(1000, ErrorMessage = "Opis može imati najviše 1000 karaktera.")]
            public string Description { get; set; } = string.Empty;

            [Required(ErrorMessage = "Adresa je obavezna.")]
            [MaxLength(200, ErrorMessage = "Adresa može imati najviše 200 karaktera.")]
            public string Address { get; set; } = string.Empty;

            public int CityId { get; set; }
            public int RentTypeId { get; set; }

            public decimal PricePerNight { get; set; }
            [Range(1, int.MaxValue, ErrorMessage = "Broj soba mora biti veći od nule.")]
            public int RoomsCount { get; set; }

            [Range(1, int.MaxValue, ErrorMessage = "Maksimalan broj gostiju mora biti veći od nule.")]
            public int MaxGuests { get; set; }

            [Range(0, (double)decimal.MaxValue, ErrorMessage = "Udaljenost od centra ne može biti negativna.")]
            public decimal DistanceToCenterKm { get; set; }

            public bool HasWifi { get; set; }
            public bool HasAirConditioning { get; set; }
            public bool PetsAllowed { get; set; }

            public string? AmenityIds { get; set; }

            public int CoverIndex { get; set; } = 0;

            public List<IFormFile> Images { get; set; } = new();
        }

        private const int MaxImagesPerListing = 10;
        private const long MaxImageSizeBytes = 5 * 1024 * 1024; // 5 MB

        private static readonly string[] AllowedImageExtensions =
        {
    ".jpg", ".jpeg", ".png", ".webp"
};

        private static readonly string[] AllowedImageContentTypes =
        {
    "image/jpeg",
    "image/png",
    "image/webp"
};

        private static async Task<bool> HasValidImageSignatureAsync(IFormFile file)
        {
            byte[] header = new byte[12];

            await using var stream = file.OpenReadStream();
            var read = await stream.ReadAsync(header, 0, header.Length);

            if (read < 4)
                return false;

            // JPEG: FF D8 FF
            if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF)
                return true;

            // PNG: 89 50 4E 47 0D 0A 1A 0A
            if (read >= 8 &&
                header[0] == 0x89 &&
                header[1] == 0x50 &&
                header[2] == 0x4E &&
                header[3] == 0x47 &&
                header[4] == 0x0D &&
                header[5] == 0x0A &&
                header[6] == 0x1A &&
                header[7] == 0x0A)
                return true;

            // WEBP: RIFF....WEBP
            if (read >= 12 &&
                header[0] == 0x52 &&
                header[1] == 0x49 &&
                header[2] == 0x46 &&
                header[3] == 0x46 &&
                header[8] == 0x57 &&
                header[9] == 0x45 &&
                header[10] == 0x42 &&
                header[11] == 0x50)
                return true;

            return false;
        }

        private static async Task<string?> ValidateImageFileAsync(IFormFile file)
        {
            if (file == null)
                return "Image file is required.";

            if (file.Length <= 0)
                return "Image file cannot be empty.";

            if (file.Length > MaxImageSizeBytes)
                return "Each image can be at most 5 MB.";

            var ext = Path.GetExtension(file.FileName).ToLowerInvariant();

            if (!AllowedImageExtensions.Contains(ext))
                return "Allowed image formats are: jpg, jpeg, png, webp.";

            var contentType = file.ContentType?.ToLowerInvariant() ?? "";

            var validContentType =
                contentType.Contains("jpeg") ||
                contentType.Contains("jpg") ||
                contentType.Contains("png") ||
                contentType.Contains("webp");

            if (!validContentType)
                return "Invalid image content type.";

            

            return null;
        }

        [HttpPost]
        [Authorize(Roles = "Admin")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> Create([FromForm] ListingCreateFormDataRequest req)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

           


            if (string.IsNullOrWhiteSpace(req.Address))
                return BadRequest("Adresa je obavezna.");

            if (req.RoomsCount <= 0)
                return BadRequest("Broj soba mora biti veći od nule.");

            if (req.MaxGuests <= 0)
                return BadRequest("Maksimalan broj gostiju mora biti veći od nule.");

            if (req.DistanceToCenterKm < 0)
                return BadRequest("Udaljenost od centra ne može biti negativna.");

            if (string.IsNullOrWhiteSpace(req.Name))
                return BadRequest("Ime je obavezno.");

            if (req.PricePerNight <= 0)
                return BadRequest("Cijena mora biti veća od 0.");

            var cityExists = await _db.Cities.AnyAsync(c => c.Id == req.CityId);
            if (!cityExists) return BadRequest("CityId is invalid.");

            var rentTypeExists = await _db.RentTypes.AnyAsync(r => r.Id == req.RentTypeId);
            if (!rentTypeExists) return BadRequest("RentTypeId is invalid.");

            if (req.Images == null || req.Images.Count == 0)
                return BadRequest("Dodaj bar jednu sliku (Images).");

            if (req.Images.Count > MaxImagesPerListing)
                return BadRequest($"You can upload at most {MaxImagesPerListing} images per listing.");

            for (int i = 0; i < req.Images.Count; i++)
            {
                var validationError = await ValidateImageFileAsync(req.Images[i]);

                if (validationError != null)
                    return BadRequest($"Image {i + 1}: {validationError}");
            }

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

            await using var transaction = await _db.Database.BeginTransactionAsync();

            string? uploadsRoot = null;

            try
            {
                var listing = new Listing
                {
                    Name = req.Name.Trim(),
                    Description = req.Description?.Trim() ?? "",
                    Address = req.Address.Trim(),
                    CityId = req.CityId,
                    RentTypeId = req.RentTypeId,
                    PricePerNight = req.PricePerNight,
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

                uploadsRoot = Path.Combine(_env.WebRootPath, "uploads", "listings", listing.Id.ToString());
                Directory.CreateDirectory(uploadsRoot);

                for (int i = 0; i < req.Images.Count; i++)
                {
                    var file = req.Images[i];
                    if (file.Length == 0) continue;

                    var ext = Path.GetExtension(file.FileName).ToLowerInvariant();

                    var fileName = $"{Guid.NewGuid()}{ext}";
                    var filePath = Path.Combine(uploadsRoot, fileName);

                    await using (var stream = new FileStream(filePath, FileMode.Create))
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

                await transaction.CommitAsync();

                return CreatedAtAction(nameof(GetById), new { id = listing.Id }, new
                {
                    listing.Id,
                    listing.Name,
                    listing.PricePerNight
                });
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();

                if (!string.IsNullOrWhiteSpace(uploadsRoot) && Directory.Exists(uploadsRoot))
                {
                    try
                    {
                        Directory.Delete(uploadsRoot, true);
                    }
                    catch
                    {
                    }
                }

                return StatusCode(500, new ApiErrorResponse
                {
                    Message = "An error occurred while creating the listing.",
                    Code = "LISTING_CREATE_FAILED"
                });
            }
        }

        [HttpPut("{id:int}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Update(int id, [FromBody] ListingCreateFormDataRequest req)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            var listing = await _db.Listings.FirstOrDefaultAsync(l => l.Id == id);

            if (listing == null)
                return NotFound("Listing not found.");

           

            if (string.IsNullOrWhiteSpace(req.Address))
                return BadRequest("Adresa je obavezna.");

            listing.Name = req.Name.Trim();
            listing.Description = req.Description?.Trim() ?? "";
            listing.Address = req.Address.Trim();
            listing.CityId = req.CityId;
            listing.RentTypeId = req.RentTypeId;
            listing.PricePerNight = req.PricePerNight;
            listing.RoomsCount = req.RoomsCount;
            listing.MaxGuests = req.MaxGuests;
            listing.DistanceToCenterKm = req.DistanceToCenterKm;
            listing.HasWifi = req.HasWifi;
            listing.HasAirConditioning = req.HasAirConditioning;
            listing.PetsAllowed = req.PetsAllowed;

            await _db.SaveChangesAsync();

            return Ok(new
            {
                message = "Listing updated successfully."
            });
        }

        [HttpPut("{id:int}/deactivate")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> Deactivate(int id)
        {
            var listing = await _db.Listings.FirstOrDefaultAsync(l => l.Id == id);

            if (listing == null)
                return NotFound("Listing not found.");

            if (!listing.IsActive)
            {
                return Ok(new
                {
                    message = "Listing is already inactive."
                });
            }

            listing.IsActive = false;

            await _db.SaveChangesAsync();

            return Ok(new
            {
                message = "Listing deactivated successfully. Existing reservations are preserved."
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
                    l.CityId,
                    l.RentTypeId,
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
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

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

            var reservations = await _db.Reservations
                .AsNoTracking()
                .Where(r =>
                    r.PropertyId == id &&
                    (r.StatusId == ReservationStatusIds.Pending ||
                     r.StatusId == ReservationStatusIds.Approved) &&
                    from < r.CheckOut &&
                    to > r.CheckIn)
                .Select(r => new { r.CheckIn, r.CheckOut })
                .ToListAsync();

            var bookedDays = new HashSet<DateTime>();

            foreach (var r in reservations)
            {
                var start = r.CheckIn.Date < from.Date ? from.Date : r.CheckIn.Date;
                var end = r.CheckOut.Date > to.Date ? to.Date : r.CheckOut.Date;

                for (var d = start; d < end; d = d.AddDays(1))
                {
                    bookedDays.Add(d);
                }
            }

            return Ok(bookedDays);
        }
    }
}