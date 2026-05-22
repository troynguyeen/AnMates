using AnMates.Domain.Enums;
using Microsoft.AspNetCore.Identity;
using NetTopologySuite.Geometries;

namespace AnMates.Domain.Entities;

// Single user entity: ASP.NET Identity columns (Email, PasswordHash, PhoneNumber,
// lockout, 2FA scaffolding) plus profile columns.  Splitting into Identity + Profile
// tables is a Phase-2 task; for MVP a single table is simpler and cheaper to join.
public class ApplicationUser : IdentityUser<Guid>
{
    // ── Profile ────────────────────────────────────────────────────────────
    public string DisplayName { get; set; } = string.Empty;
    public string? Bio { get; set; }
    public string? AvatarUrl { get; set; }
    public DateOnly? DateOfBirth { get; set; }
    public Gender Gender { get; set; } = Gender.Unspecified;
    public Personality Personality { get; set; } = Personality.Unspecified;
    public Intention Intention { get; set; } = Intention.Friendship;

    // Food preference & vibe tags stored as Postgres text[] (mapped via Npgsql).
    public string[] VibeTags { get; set; } = [];
    public string[] FoodPreferenceTags { get; set; } = [];

    // ── Verification & Trust ───────────────────────────────────────────────
    public bool IsFaceVerified { get; set; }
    public DateTimeOffset? FaceVerifiedAt { get; set; }

    // TrustScore is computed; persisted for fast filtering.  Range 0.00 — 100.00.
    public decimal TrustScore { get; set; } = 50m;

    // ── Geolocation (last known) ───────────────────────────────────────────
    // SRID 4326 (WGS84).  geography(Point) gives metre-accurate distance queries.
    public Point? LastLocation { get; set; }
    public DateTimeOffset? LastLocationAt { get; set; }

    // ── Lifecycle ──────────────────────────────────────────────────────────
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? LastActiveAt { get; set; }
    public DateTimeOffset? DeactivatedAt { get; set; }

    // ── Navigation ─────────────────────────────────────────────────────────
    public ICollection<FoodWishlistItem> WishlistItems { get; set; } = [];
}

public class ApplicationRole : IdentityRole<Guid>
{
    public ApplicationRole() { }
    public ApplicationRole(string name) : base(name) { }
}
