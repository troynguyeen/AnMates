using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using AnMates.Domain.Entities;
using AnMates.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace AnMates.Api.Modules.Identity.Services;

public sealed class TokenServiceOptions
{
    public const string SectionName = "Jwt";
    public string Issuer { get; set; } = string.Empty;
    public string Audience { get; set; } = string.Empty;
    public string SigningKey { get; set; } = string.Empty;
    public int AccessTokenMinutes { get; set; } = 15;
    public int RefreshTokenDays { get; set; } = 30;
}

public sealed class TokenService : ITokenService
{
    private readonly AnMatesDbContext _db;
    private readonly TokenServiceOptions _opts;

    public TokenService(AnMatesDbContext db, IOptions<TokenServiceOptions> opts)
    {
        _db = db;
        _opts = opts.Value;
    }

    public string GenerateAccessToken(ApplicationUser user)
    {
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new(JwtRegisteredClaimNames.GivenName, user.DisplayName),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new("verified", user.IsFaceVerified ? "1" : "0"),
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_opts.SigningKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(
            issuer: _opts.Issuer,
            audience: _opts.Audience,
            claims: claims,
            notBefore: DateTime.UtcNow,
            expires: DateTime.UtcNow.AddMinutes(_opts.AccessTokenMinutes),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public DateTimeOffset AccessTokenExpiresAt() =>
        DateTimeOffset.UtcNow.AddMinutes(_opts.AccessTokenMinutes);

    public async Task<string> CreateRefreshTokenAsync(Guid userId, CancellationToken ct = default)
    {
        var (raw, hash) = GenerateTokenPair();
        _db.RefreshTokens.Add(new RefreshToken
        {
            UserId = userId,
            TokenHash = hash,
            ExpiresAt = DateTimeOffset.UtcNow.AddDays(_opts.RefreshTokenDays),
        });
        await _db.SaveChangesAsync(ct);
        return raw;
    }

    public async Task<(ApplicationUser user, string newRawToken)> RotateRefreshTokenAsync(
        string rawToken, CancellationToken ct = default)
    {
        var hash = Hash(rawToken);
        var token = await _db.RefreshTokens
            .Include(r => r.User)
            .SingleOrDefaultAsync(r => r.TokenHash == hash, ct)
            ?? throw new InvalidOperationException("Token not found.");

        if (!token.IsActive)
        {
            // Token reuse detected — revoke the whole chain to protect the account.
            if (!string.IsNullOrEmpty(token.ReplacedByTokenHash))
                await RevokeChainAsync(token.ReplacedByTokenHash, "token_reuse_detected", ct);

            throw new InvalidOperationException("Refresh token is no longer active.");
        }

        var (newRaw, newHash) = GenerateTokenPair();
        token.RevokedAt = DateTimeOffset.UtcNow;
        token.ReplacedByTokenHash = newHash;
        token.RevokedReason = "rotated";

        _db.RefreshTokens.Add(new RefreshToken
        {
            UserId = token.UserId,
            TokenHash = newHash,
            ExpiresAt = DateTimeOffset.UtcNow.AddDays(_opts.RefreshTokenDays),
        });
        await _db.SaveChangesAsync(ct);
        return (token.User, newRaw);
    }

    public async Task RevokeRefreshTokenAsync(string rawToken, string reason, CancellationToken ct = default)
    {
        var hash = Hash(rawToken);
        var token = await _db.RefreshTokens
            .SingleOrDefaultAsync(r => r.TokenHash == hash, ct);
        if (token is null || !token.IsActive) return;

        token.RevokedAt = DateTimeOffset.UtcNow;
        token.RevokedReason = reason;
        await _db.SaveChangesAsync(ct);
    }

    public async Task PurgeExpiredTokensAsync(int retentionDays = 30, CancellationToken ct = default)
    {
        var cutoff = DateTimeOffset.UtcNow.AddDays(-retentionDays);
        await _db.RefreshTokens
            .Where(r => r.ExpiresAt < cutoff || (r.IsRevoked && r.RevokedAt < cutoff))
            .ExecuteDeleteAsync(ct);
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    // Returns (rawToken, sha256HashBase64).
    private static (string raw, string hash) GenerateTokenPair()
    {
        var bytes = RandomNumberGenerator.GetBytes(64);
        var raw = Convert.ToBase64String(bytes);
        return (raw, Hash(raw));
    }

    private static string Hash(string raw)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(raw));
        return Convert.ToBase64String(bytes);
    }

    private async Task RevokeChainAsync(string tokenHash, string reason, CancellationToken ct)
    {
        var token = await _db.RefreshTokens
            .SingleOrDefaultAsync(r => r.TokenHash == tokenHash, ct);
        if (token is null || token.IsRevoked) return;

        token.RevokedAt = DateTimeOffset.UtcNow;
        token.RevokedReason = reason;
        await _db.SaveChangesAsync(ct);

        if (!string.IsNullOrEmpty(token.ReplacedByTokenHash))
            await RevokeChainAsync(token.ReplacedByTokenHash, reason, ct);
    }
}
