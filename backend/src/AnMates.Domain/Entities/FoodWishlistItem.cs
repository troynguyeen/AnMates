using AnMates.Domain.Enums;
using NetTopologySuite.Geometries;

namespace AnMates.Domain.Entities;

// A user-curated "want to try" item. Drives Shared Wishlist Matching.
public class FoodWishlistItem
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid UserId { get; set; }
    public ApplicationUser User { get; set; } = null!;

    // Either a curated Place or a free-form spot the user added.
    public Guid? PlaceId { get; set; }
    public Place? Place { get; set; }

    public string PlaceName { get; set; } = string.Empty;
    public Point Location { get; set; } = null!;

    public WishlistStatus Status { get; set; } = WishlistStatus.LookingForCompanion;
    public string? Note { get; set; }

    // Optional time window: "after 2026-06-01", "this weekend", etc.
    public DateTimeOffset? AvailableFrom { get; set; }
    public DateTimeOffset? AvailableUntil { get; set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? CompletedAt { get; set; }
}
