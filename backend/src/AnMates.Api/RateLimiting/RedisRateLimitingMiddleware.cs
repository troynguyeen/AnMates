using System.Diagnostics;
using System.Globalization;
using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Http.Extensions;
using Microsoft.Extensions.Options;
using StackExchange.Redis;

namespace AnMates.Api.RateLimiting;

// Distributed token-bucket rate limiter. One Redis round-trip per request,
// implemented with EVALSHA + cached SHA1 to avoid re-shipping the Lua source.
//
// Contract:
//  - 1 request / 2 seconds sustained (0.5 RPS).
//  - Burst pool of 5 tokens.
//  - Partition by authenticated user id; fall back to client IP.
//  - On exceed: HTTP 429 with `Retry-After` (seconds) and `X-RateLimit-*` headers.
//  - If Redis is unreachable for longer than the configured grace window, the
//    middleware fails open and logs a warning.  This is a deliberate availability
//    tradeoff for MVP — flip RedisFailureFailOpenAfterMs to 0 to fail closed.
public sealed class RedisRateLimitingMiddleware : IDisposable
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    private readonly RequestDelegate _next;
    private readonly IConnectionMultiplexer _redis;
    private readonly RedisRateLimiterOptions _options;
    private readonly ILogger<RedisRateLimitingMiddleware> _log;

    // Cached script SHA1, populated lazily on first call.
    private byte[]? _scriptSha;
    private readonly SemaphoreSlim _shaLock = new(1, 1);

    // Tracks consecutive Redis failures so we can flip into fail-open mode.
    private long _firstFailureAtTicks;

    public RedisRateLimitingMiddleware(
        RequestDelegate next,
        IConnectionMultiplexer redis,
        IOptions<RedisRateLimiterOptions> options,
        ILogger<RedisRateLimitingMiddleware> log)
    {
        _next = next;
        _redis = redis;
        _options = options.Value;
        _log = log;
    }

    public async Task InvokeAsync(HttpContext ctx)
    {
        if (ShouldBypass(ctx))
        {
            await _next(ctx);
            return;
        }

        var partitionKey = ResolvePartitionKey(ctx);
        if (partitionKey is null)
        {
            // Anonymous + IP-partitioning disabled → reject loudly rather than
            // collapse everyone into a shared bucket.
            await WriteRateLimitResponse(ctx, retryAfterSeconds: 2, remaining: 0);
            return;
        }

        var redisKey = $"{_options.KeyPrefix}:{partitionKey}";
        try
        {
            var (allowed, remaining, retryAfterMs) =
                await EvaluateBucketAsync(redisKey, ctx.RequestAborted);

            // Reset failure tracking when Redis recovers.
            Interlocked.Exchange(ref _firstFailureAtTicks, 0);

            ctx.Response.Headers["X-RateLimit-Limit"] =
                _options.Capacity.ToString(CultureInfo.InvariantCulture);
            ctx.Response.Headers["X-RateLimit-Remaining"] =
                Math.Floor(remaining).ToString(CultureInfo.InvariantCulture);

            if (!allowed)
            {
                var retryAfterSeconds = (int)Math.Max(1, Math.Ceiling(retryAfterMs / 1000.0));
                await WriteRateLimitResponse(ctx, retryAfterSeconds, remaining);
                return;
            }

            await _next(ctx);
        }
        catch (Exception ex) when (ex is RedisException or RedisTimeoutException or RedisConnectionException)
        {
            if (ShouldFailOpen())
            {
                RateLimiterLog.FailingOpen(_log, ex, _options.RedisFailureFailOpenAfterMs, ctx.Request.GetDisplayUrl());
                await _next(ctx);
                return;
            }

            RateLimiterLog.FailingClosed(_log, ex, ctx.Request.GetDisplayUrl());
            await WriteRateLimitResponse(ctx, retryAfterSeconds: 1, remaining: 0);
        }
    }

    private bool ShouldBypass(HttpContext ctx)
    {
        var path = ctx.Request.Path.Value;
        if (string.IsNullOrEmpty(path)) return false;

        foreach (var prefix in _options.BypassPathPrefixes)
        {
            if (path.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
                return true;
        }
        return false;
    }

    private string? ResolvePartitionKey(HttpContext ctx)
    {
        var userId = ctx.User?.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!string.IsNullOrEmpty(userId))
            return $"user:{userId}";

        if (!_options.LimitAnonymousByIp)
            return null;

        // RemoteIpAddress already reflects the X-Forwarded-For chain because
        // ForwardedHeaders middleware runs before us.
        var ip = ctx.Connection.RemoteIpAddress?.ToString();
        return string.IsNullOrEmpty(ip) ? "ip:unknown" : $"ip:{ip}";
    }

    private async Task<(bool allowed, double remaining, long retryAfterMs)> EvaluateBucketAsync(
        string redisKey, CancellationToken ct)
    {
        var db = _redis.GetDatabase();
        var nowMs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();

        // Idle TTL: enough time to refill the bucket twice over.
        var ttlMs = (long)Math.Max(
            10_000,
            (_options.Capacity / _options.RefillRatePerSecond) * 1000 * 2);

        var args = new RedisValue[]
        {
            _options.Capacity,
            _options.RefillRatePerSecond,
            nowMs,
            1, // cost
            ttlMs,
        };
        var keys = new RedisKey[] { redisKey };

        // Try EVALSHA first; fall back to EVAL on NOSCRIPT.
        await EnsureScriptLoadedAsync().ConfigureAwait(false);

        RedisResult result;
        try
        {
            result = await db.ScriptEvaluateAsync(_scriptSha!, keys, args).ConfigureAwait(false);
        }
        catch (RedisServerException ex) when (ex.Message.StartsWith("NOSCRIPT", StringComparison.Ordinal))
        {
            // Server flushed scripts (failover, FLUSHALL on another shard).  Re-load and retry once.
            await ReloadScriptAsync().ConfigureAwait(false);
            result = await db.ScriptEvaluateAsync(_scriptSha!, keys, args).ConfigureAwait(false);
        }

        var values = (RedisValue[])result!;
        var allowed = (long)values[0] == 1;
        var remaining = (double)values[1];
        var retryAfterMs = (long)values[2];
        return (allowed, remaining, retryAfterMs);
    }

    private async Task EnsureScriptLoadedAsync()
    {
        if (_scriptSha is not null) return;
        await _shaLock.WaitAsync().ConfigureAwait(false);
        try
        {
            if (_scriptSha is null) await LoadScriptInternalAsync().ConfigureAwait(false);
        }
        finally { _shaLock.Release(); }
    }

    private async Task ReloadScriptAsync()
    {
        await _shaLock.WaitAsync().ConfigureAwait(false);
        try
        {
            await LoadScriptInternalAsync().ConfigureAwait(false);
        }
        finally { _shaLock.Release(); }
    }

    private async Task LoadScriptInternalAsync()
    {
        // Load on every endpoint we might evaluate against.  For a single Redis it's one call.
        byte[]? sha = null;
        foreach (var ep in _redis.GetEndPoints())
        {
            var server = _redis.GetServer(ep);
            if (!server.IsConnected || server.IsReplica) continue;
            sha = await server.ScriptLoadAsync(TokenBucketScript.Lua).ConfigureAwait(false);
        }

        if (sha is null)
            throw new RedisException("Unable to load rate-limit script: no connected primary.");

        _scriptSha = sha;
    }

    private bool ShouldFailOpen()
    {
        if (_options.RedisFailureFailOpenAfterMs <= 0) return false;

        var nowTicks = Stopwatch.GetTimestamp();
        var first = Interlocked.CompareExchange(ref _firstFailureAtTicks, nowTicks, 0);
        if (first == 0) return false;       // First failure → still fail-closed.

        var elapsedMs = (nowTicks - first) * 1000.0 / Stopwatch.Frequency;
        return elapsedMs >= _options.RedisFailureFailOpenAfterMs;
    }

    private static Task WriteRateLimitResponse(HttpContext ctx, int retryAfterSeconds, double remaining)
    {
        ctx.Response.StatusCode = StatusCodes.Status429TooManyRequests;
        ctx.Response.ContentType = "application/problem+json";
        ctx.Response.Headers["Retry-After"] =
            retryAfterSeconds.ToString(CultureInfo.InvariantCulture);
        ctx.Response.Headers["X-RateLimit-Remaining"] =
            Math.Max(0, Math.Floor(remaining)).ToString(CultureInfo.InvariantCulture);

        // RFC 7807 problem details — Flutter/mobile clients parse this format.
        var payload = new
        {
            type = "https://anmates.example.com/errors/rate-limited",
            title = "Too many requests",
            status = 429,
            detail = $"Rate limit exceeded. Retry after {retryAfterSeconds} second(s).",
            retryAfterSeconds,
        };
        return ctx.Response.WriteAsync(JsonSerializer.Serialize(payload, JsonOptions));
    }

    public void Dispose() => _shaLock.Dispose();
}

// High-performance log delegates (CA1848).
internal static partial class RateLimiterLog
{
    [LoggerMessage(EventId = 2001, Level = LogLevel.Warning,
        Message = "Rate limiter Redis backend unavailable for >{GraceMs}ms; failing open for {Url}")]
    public static partial void FailingOpen(ILogger logger, Exception ex, int graceMs, string url);

    [LoggerMessage(EventId = 2002, Level = LogLevel.Error,
        Message = "Rate limiter Redis backend unavailable; failing closed for {Url}")]
    public static partial void FailingClosed(ILogger logger, Exception ex, string url);
}
