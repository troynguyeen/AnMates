using NetTopologySuite.Geometries;

namespace AnMates.Domain.Entities;

// Curated venues. Wishlist items reference a Place when known, otherwise carry
// free-form name + coordinates (user added an unknown spot).
public class Place
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Address { get; set; }
    public string Category { get; set; } = "Restaurant";

    // SRID 4326. PostGIS geography column — see DbContext config.
    public Point Location { get; set; } = null!;

    public string PriceRange { get; set; } = "$$";       // $, $$, $$$, $$$$
    public decimal AverageRating { get; set; } = 0m;
    public int RatingCount { get; set; }

    public string[] VibeTags { get; set; } = [];
    public string[] CuisineTags { get; set; } = [];
    public string[] PhotoUrls { get; set; } = [];

    // jsonb { mon: [["09:00","22:00"]], ... }
    public string? OperatingHoursJson { get; set; }

    public bool IsVibeCheckFriendly { get; set; }
    public bool IsPartner { get; set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? UpdatedAt { get; set; }
}
