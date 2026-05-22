using AnMates.Api.Modules.Identity.DTOs;
using AnMates.Api.Modules.Identity.Services;
using AnMates.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace AnMates.Api.Modules.Identity;

[ApiController]
[Route("api/auth")]
[Produces("application/json")]
public sealed class AuthController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _users;
    private readonly ITokenService _tokens;
    private readonly ILogger<AuthController> _log;

    public AuthController(
        UserManager<ApplicationUser> users,
        ITokenService tokens,
        ILogger<AuthController> log)
    {
        _users = users;
        _tokens = tokens;
        _log = log;
    }

    /// <summary>Register a new account.</summary>
    /// <response code="201">Account created; returns tokens.</response>
    /// <response code="409">Email already in use.</response>
    [HttpPost("register")]
    [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Register(
        [FromBody] RegisterRequest req, CancellationToken ct)
    {
        var existing = await _users.FindByEmailAsync(req.Email);
        if (existing is not null)
            return Conflict(new { error = "email_taken", detail = "This email is already registered." });

        var user = new ApplicationUser
        {
            UserName = req.Email,
            Email = req.Email,
            DisplayName = req.DisplayName,
            PhoneNumber = req.PhoneNumber,
        };

        var result = await _users.CreateAsync(user, req.Password);
        if (!result.Succeeded)
        {
            var errors = result.Errors.Select(e => new { e.Code, e.Description });
            return UnprocessableEntity(new { error = "validation_failed", errors });
        }

        Log.UserRegistered(_log, user.Id);

        var accessToken = _tokens.GenerateAccessToken(user);
        var refreshRaw = await _tokens.CreateRefreshTokenAsync(user.Id, ct);
        return CreatedAtAction(
            nameof(ProfileController.GetMe),
            controllerName: "Profile",
            routeValues: null,
            value: BuildAuthResponse(user, accessToken, refreshRaw));
    }

    /// <summary>Authenticate and receive tokens.</summary>
    /// <response code="200">Credentials valid; tokens returned.</response>
    /// <response code="401">Invalid credentials or account locked.</response>
    [HttpPost("login")]
    [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Login(
        [FromBody] LoginRequest req, CancellationToken ct)
    {
        var user = await _users.FindByEmailAsync(req.Email);
        if (user is null || user.DeactivatedAt.HasValue)
            return Unauthorized(new { error = "invalid_credentials" });

        if (await _users.IsLockedOutAsync(user))
        {
            var lockoutEnd = await _users.GetLockoutEndDateAsync(user);
            return Unauthorized(new
            {
                error = "account_locked",
                detail = $"Account is temporarily locked. Try again after {lockoutEnd:o}.",
            });
        }

        var valid = await _users.CheckPasswordAsync(user, req.Password);
        if (!valid)
        {
            await _users.AccessFailedAsync(user);
            return Unauthorized(new { error = "invalid_credentials" });
        }

        await _users.ResetAccessFailedCountAsync(user);
        await _users.SetLastActiveAsync(user);

        var accessToken = _tokens.GenerateAccessToken(user);
        var refreshRaw = await _tokens.CreateRefreshTokenAsync(user.Id, ct);

        Log.UserLoggedIn(_log, user.Id, HttpContext.Connection.RemoteIpAddress?.ToString() ?? "-");

        return Ok(BuildAuthResponse(user, accessToken, refreshRaw));
    }

    /// <summary>Exchange a refresh token for a new token pair.</summary>
    /// <response code="200">New tokens issued.</response>
    /// <response code="401">Refresh token invalid, expired, or reused.</response>
    [HttpPost("refresh")]
    [ProducesResponseType(typeof(AuthResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Refresh(
        [FromBody] RefreshTokenRequest req, CancellationToken ct)
    {
        try
        {
            var (user, newRaw) = await _tokens.RotateRefreshTokenAsync(req.RefreshToken, ct);
            var accessToken = _tokens.GenerateAccessToken(user);
            return Ok(BuildAuthResponse(user, accessToken, newRaw));
        }
        catch (InvalidOperationException ex)
        {
            Log.RefreshTokenRejected(_log, ex.Message);
            return Unauthorized(new { error = "invalid_refresh_token" });
        }
    }

    /// <summary>Revoke the supplied refresh token (logout from one device).</summary>
    /// <response code="204">Token revoked.</response>
    [HttpDelete("logout")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Logout(
        [FromBody] RefreshTokenRequest req, CancellationToken ct)
    {
        await _tokens.RevokeRefreshTokenAsync(req.RefreshToken, "logout", ct);
        return NoContent();
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    private AuthResponse BuildAuthResponse(ApplicationUser user, string accessToken, string refreshRaw) =>
        new(
            AccessToken: accessToken,
            ExpiresAt: _tokens.AccessTokenExpiresAt(),
            RefreshToken: refreshRaw,
            RefreshExpiresAt: DateTimeOffset.UtcNow.AddDays(30),
            User: ToDto(user)
        );

    internal static UserDto ToDto(ApplicationUser u) => new(
        u.Id, u.DisplayName, u.Email!, u.PhoneNumber,
        u.AvatarUrl, u.Bio, u.Gender, u.Personality, u.Intention,
        u.VibeTags, u.FoodPreferenceTags, u.IsFaceVerified, u.TrustScore, u.CreatedAt);
}

// High-performance structured log messages (CA1848).
internal static partial class Log
{
    [LoggerMessage(EventId = 1001, Level = LogLevel.Information, Message = "New user registered: {UserId}")]
    public static partial void UserRegistered(ILogger logger, Guid userId);

    [LoggerMessage(EventId = 1002, Level = LogLevel.Information, Message = "User {UserId} logged in from {Ip}")]
    public static partial void UserLoggedIn(ILogger logger, Guid userId, string ip);

    [LoggerMessage(EventId = 1003, Level = LogLevel.Warning, Message = "Refresh token rejected: {Reason}")]
    public static partial void RefreshTokenRejected(ILogger logger, string reason);
}

// Extension: update last-active timestamp without loading identity machinery.
internal static class UserManagerExtensions
{
    public static async Task SetLastActiveAsync(
        this UserManager<ApplicationUser> mgr, ApplicationUser user)
    {
        user.LastActiveAt = DateTimeOffset.UtcNow;
        await mgr.UpdateAsync(user);
    }
}
