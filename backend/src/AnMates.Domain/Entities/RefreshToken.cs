namespace AnMates.Domain.Entities;

// Opaque rotating refresh token. Raw token is never stored — only SHA-256 hash.
// On use: mark IsRevoked + create replacement; client receives new raw token.
public class RefreshToken
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid UserId { get; set; }
    public ApplicationUser User { get; set; } = null!;

    // SHA-256(rawToken) — never store the raw value.
    public string TokenHash { get; set; } = string.Empty;

    public DateTimeOffset ExpiresAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;

    // Filled when revoked. If replaced, points to the successor token's hash.
    public DateTimeOffset? RevokedAt { get; set; }
    public string? ReplacedByTokenHash { get; set; }
    public string? RevokedReason { get; set; }

    public bool IsRevoked => RevokedAt.HasValue;
    public bool IsExpired => DateTimeOffset.UtcNow >= ExpiresAt;
    public bool IsActive => !IsRevoked && !IsExpired;
}
