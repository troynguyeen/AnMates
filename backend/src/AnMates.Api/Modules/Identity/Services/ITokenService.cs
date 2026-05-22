using AnMates.Domain.Entities;

namespace AnMates.Api.Modules.Identity.Services;

public interface ITokenService
{
    string GenerateAccessToken(ApplicationUser user);
    DateTimeOffset AccessTokenExpiresAt();

    // Returns the raw (unhashed) refresh token.
    // Stores the hash in DB.
    Task<string> CreateRefreshTokenAsync(Guid userId, CancellationToken ct = default);

    // Rotates the token: revokes old, issues new, returns new raw token.
    // Throws InvalidOperationException if old token is inactive.
    Task<(ApplicationUser user, string newRawToken)> RotateRefreshTokenAsync(
        string rawToken, CancellationToken ct = default);

    Task RevokeRefreshTokenAsync(string rawToken, string reason, CancellationToken ct = default);

    // Cleans expired/revoked tokens older than retentionDays.
    Task PurgeExpiredTokensAsync(int retentionDays = 30, CancellationToken ct = default);
}
