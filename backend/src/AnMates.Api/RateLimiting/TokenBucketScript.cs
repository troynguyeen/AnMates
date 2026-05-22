namespace AnMates.Api.RateLimiting;

// Atomic token-bucket maintained in a Redis hash.
//
// KEYS[1] = bucket key, e.g. "rl:v1:user:<guid>"
// ARGV[1] = capacity (burst pool size)
// ARGV[2] = refill rate, tokens per second (float)
// ARGV[3] = now, milliseconds since epoch
// ARGV[4] = cost of this request (typically 1)
// ARGV[5] = key TTL in ms (bucket auto-expires when idle)
//
// Returns { allowed (1|0), remainingTokens, retryAfterMs }
internal static class TokenBucketScript
{
    public const string Lua = """
        local key          = KEYS[1]
        local capacity     = tonumber(ARGV[1])
        local refill_rate  = tonumber(ARGV[2])
        local now_ms       = tonumber(ARGV[3])
        local cost         = tonumber(ARGV[4])
        local ttl_ms       = tonumber(ARGV[5])

        local data         = redis.call('HMGET', key, 'tokens', 'ts')
        local tokens       = tonumber(data[1])
        local last_ts      = tonumber(data[2])

        if tokens == nil then
          tokens  = capacity
          last_ts = now_ms
        else
          local elapsed_s = math.max(0, now_ms - last_ts) / 1000.0
          tokens          = math.min(capacity, tokens + elapsed_s * refill_rate)
          last_ts         = now_ms
        end

        local allowed        = 0
        local retry_after_ms = 0

        if tokens >= cost then
          tokens  = tokens - cost
          allowed = 1
        else
          local needed    = cost - tokens
          retry_after_ms  = math.ceil((needed / refill_rate) * 1000)
        end

        redis.call('HMSET', key, 'tokens', tokens, 'ts', last_ts)
        redis.call('PEXPIRE', key, ttl_ms)

        return { allowed, tokens, retry_after_ms }
        """;
}
