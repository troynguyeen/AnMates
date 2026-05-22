using System.ComponentModel.DataAnnotations;
using AnMates.Domain.Enums;

namespace AnMates.Api.Modules.Identity.DTOs;

// ── Requests ──────────────────────────────────────────────────────────────

public sealed record RegisterRequest
{
    [Required, MaxLength(80)]
    public string DisplayName { get; init; } = string.Empty;

    [Required, EmailAddress, MaxLength(256)]
    public string Email { get; init; } = string.Empty;

    [Required, MinLength(10), MaxLength(128)]
    public string Password { get; init; } = string.Empty;

    // Optional — verified with OTP in Sprint 3.
    [Phone, MaxLength(20)]
    public string? PhoneNumber { get; init; }
}

public sealed record LoginRequest
{
    [Required, EmailAddress]
    public string Email { get; init; } = string.Empty;

    [Required]
    public string Password { get; init; } = string.Empty;
}

public sealed record RefreshTokenRequest
{
    [Required]
    public string RefreshToken { get; init; } = string.Empty;
}

// ── Responses ─────────────────────────────────────────────────────────────

public sealed record AuthResponse(
    string AccessToken,
    DateTimeOffset ExpiresAt,
    string RefreshToken,
    DateTimeOffset RefreshExpiresAt,
    UserDto User
);

public sealed record UserDto(
    Guid Id,
    string DisplayName,
    string Email,
    string? PhoneNumber,
    string? AvatarUrl,
    string? Bio,
    Gender Gender,
    Personality Personality,
    Intention Intention,
    string[] VibeTags,
    string[] FoodPreferenceTags,
    bool IsFaceVerified,
    decimal TrustScore,
    DateTimeOffset CreatedAt
);
