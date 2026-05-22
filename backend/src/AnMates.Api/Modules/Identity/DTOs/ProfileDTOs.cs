using System.ComponentModel.DataAnnotations;
using AnMates.Domain.Enums;

namespace AnMates.Api.Modules.Identity.DTOs;

public sealed record UpdateProfileRequest
{
    [MaxLength(80)]
    public string? DisplayName { get; init; }

    [MaxLength(500)]
    public string? Bio { get; init; }

    public Gender? Gender { get; init; }
    public Personality? Personality { get; init; }
    public Intention? Intention { get; init; }
    public DateOnly? DateOfBirth { get; init; }

    public string[]? VibeTags { get; init; }
    public string[]? FoodPreferenceTags { get; init; }
}

public sealed record UpdateLocationRequest
{
    [Required, Range(-90, 90)]
    public double Latitude { get; init; }

    [Required, Range(-180, 180)]
    public double Longitude { get; init; }
}
