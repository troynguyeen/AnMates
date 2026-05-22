using AnMates.Domain.Enums;

namespace AnMates.Domain.Entities;

// A match between two users.  Invariant: UserAId < UserBId (lexicographic) so
// there is exactly one row per pair.  Enforced by a check constraint + unique index.
public class Match
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid UserAId { get; set; }
    public ApplicationUser UserA { get; set; } = null!;

    public Guid UserBId { get; set; }
    public ApplicationUser UserB { get; set; } = null!;

    public MatchMode Mode { get; set; } = MatchMode.ActivityFood;
    public MatchStatus Status { get; set; } = MatchStatus.Pending;

    // VibeScore: 0–100.  Computed at match creation; recomputed on profile changes.
    public decimal VibeScore { get; set; }

    // FriendshipProgress: 0–100.  Updates from ChatMessage.WeightScore aggregation.
    // When this crosses InviteUnlockThreshold (default 70), the "Send Invite"
    // affordance unlocks in the client.
    public int FriendshipProgress { get; set; }

    public bool InviteUnlocked { get; set; }
    public DateTimeOffset? InviteUnlockedAt { get; set; }

    // Snapshot of shared wishlist item ids at match time (jsonb in PG).
    public Guid[] SharedWishlistItemIds { get; set; } = [];

    public DateTimeOffset MatchedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? LastMessageAt { get; set; }
    public DateTimeOffset? ExpiresAt { get; set; }   // unused chat auto-expires
    public DateTimeOffset? ClosedAt { get; set; }

    public ICollection<ChatMessage> Messages { get; set; } = [];
}
