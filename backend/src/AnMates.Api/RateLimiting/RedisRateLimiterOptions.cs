namespace AnMates.Api.RateLimiting;

public sealed class RedisRateLimiterOptions
{
    public const string SectionName = "RateLimit";

    // Burst pool size.  After exhausting the pool, requests are throttled at
    // RefillRatePerSecond.  Default: 5 (per project spec).
    public int Capacity { get; set; } = 5;

    // Sustained rate, tokens per second.  0.5 == 1 request every 2 seconds.
    public double RefillRatePerSecond { get; set; } = 0.5;

    // Redis key namespace.
    public string KeyPrefix { get; set; } = "rl:v1";

    // When true, anonymous callers are limited by client IP; when false, anonymous
    // requests share a single bucket called "anon" (use only behind a tight WAF).
    public bool LimitAnonymousByIp { get; set; } = true;

    // Routes that bypass the limiter entirely (health, metrics, SignalR negotiate
    // — SignalR has its own quota wired in HubFilter).
    public string[] BypassPathPrefixes { get; set; } =
    [
        "/health",
        "/ready",
        "/metrics",
    ];

    // Fail-open if Redis is unreachable for longer than this.  Set to 0 to fail-closed.
    public int RedisFailureFailOpenAfterMs { get; set; } = 1_000;
}
