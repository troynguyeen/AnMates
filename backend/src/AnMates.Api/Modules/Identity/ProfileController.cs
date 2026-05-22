using System.Security.Claims;
using AnMates.Api.Modules.Identity.DTOs;
using AnMates.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using NetTopologySuite.Geometries;

namespace AnMates.Api.Modules.Identity;

[ApiController]
[Route("api/me")]
[Authorize]
[Produces("application/json")]
public sealed class ProfileController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _users;

    public ProfileController(UserManager<ApplicationUser> users) => _users = users;

    /// <summary>Get the authenticated user's profile.</summary>
    /// <response code="200">Current user's profile data.</response>
    [HttpGet(Name = nameof(GetMe))]
    [ProducesResponseType(typeof(UserDto), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMe()
    {
        var user = await GetCurrentUserAsync();
        if (user is null) return Unauthorized();
        return Ok(AuthController.ToDto(user));
    }

    /// <summary>Partially update the authenticated user's profile.</summary>
    /// <response code="200">Updated profile.</response>
    [HttpPatch]
    [ProducesResponseType(typeof(UserDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status422UnprocessableEntity)]
    public async Task<IActionResult> UpdateProfile(
        [FromBody] UpdateProfileRequest req)
    {
        var user = await GetCurrentUserAsync();
        if (user is null) return Unauthorized();

        if (req.DisplayName is not null) user.DisplayName = req.DisplayName;
        if (req.Bio is not null) user.Bio = req.Bio;
        if (req.Gender.HasValue) user.Gender = req.Gender.Value;
        if (req.Personality.HasValue) user.Personality = req.Personality.Value;
        if (req.Intention.HasValue) user.Intention = req.Intention.Value;
        if (req.DateOfBirth.HasValue) user.DateOfBirth = req.DateOfBirth.Value;
        if (req.VibeTags is not null) user.VibeTags = req.VibeTags;
        if (req.FoodPreferenceTags is not null) user.FoodPreferenceTags = req.FoodPreferenceTags;

        var result = await _users.UpdateAsync(user);
        if (!result.Succeeded)
        {
            var errors = result.Errors.Select(e => new { e.Code, e.Description });
            return UnprocessableEntity(new { error = "update_failed", errors });
        }

        return Ok(AuthController.ToDto(user));
    }

    /// <summary>
    /// Update the user's last known location.  Called by the mobile client
    /// periodically in the background (max every 5 minutes per the client).
    /// </summary>
    /// <response code="204">Location updated.</response>
    [HttpPut("location")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> UpdateLocation([FromBody] UpdateLocationRequest req)
    {
        var user = await GetCurrentUserAsync();
        if (user is null) return Unauthorized();

        // SRID 4326 — PostGIS geography uses lon/lat order.
        user.LastLocation = new Point(req.Longitude, req.Latitude) { SRID = 4326 };
        user.LastLocationAt = DateTimeOffset.UtcNow;

        await _users.UpdateAsync(user);
        return NoContent();
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    private Task<ApplicationUser?> GetCurrentUserAsync()
    {
        var id = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return id is null
            ? Task.FromResult<ApplicationUser?>(null)
            : _users.FindByIdAsync(id)!;
    }
}
