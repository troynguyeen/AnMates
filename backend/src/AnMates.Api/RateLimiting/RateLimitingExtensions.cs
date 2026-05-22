using Microsoft.Extensions.Options;

namespace AnMates.Api.RateLimiting;

public static class RateLimitingExtensions
{
    public static IServiceCollection AddRedisRateLimiting(
        this IServiceCollection services, IConfiguration config)
    {
        services
            .AddOptions<RedisRateLimiterOptions>()
            .Bind(config.GetSection(RedisRateLimiterOptions.SectionName))
            .Validate(o => o.Capacity > 0, "RateLimit:Capacity must be > 0.")
            .Validate(o => o.RefillRatePerSecond > 0, "RateLimit:RefillRatePerSecond must be > 0.")
            .ValidateOnStart();
        return services;
    }

    public static IApplicationBuilder UseRedisRateLimiting(this IApplicationBuilder app)
        => app.UseMiddleware<RedisRateLimitingMiddleware>();
}
