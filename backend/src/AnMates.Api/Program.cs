using System.Text;
using AnMates.Api.Modules.Identity.Services;
using AnMates.Api.RateLimiting;
using AnMates.Domain.Entities;
using AnMates.Infrastructure.Data;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using Serilog;
using Serilog.Sinks.Grafana.Loki;
using StackExchange.Redis;

var builder = WebApplication.CreateBuilder(args);

// ── Logging: Serilog → stdout + Loki ─────────────────────────────────────
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .Enrich.WithProperty("service", "anmates-api")
    .WriteTo.Console(formatProvider: System.Globalization.CultureInfo.InvariantCulture)
    .WriteTo.GrafanaLoki(
        builder.Configuration["Serilog:WriteTo:1:Args:uri"] ?? "http://loki:3100",
        labels: [new LokiLabel { Key = "service", Value = "anmates-api" }],
        propertiesAsLabels: ["level"])
    .CreateLogger();
builder.Host.UseSerilog();

// ── Forwarded headers (we're behind Caddy) ───────────────────────────────
builder.Services.Configure<ForwardedHeadersOptions>(o =>
{
    o.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    o.KnownNetworks.Clear();
    o.KnownProxies.Clear();
    // Trust everything on the docker bridge. In multi-host setups, list proxy IPs explicitly.
    o.ForwardLimit = 2;
});

// ── EF Core ──────────────────────────────────────────────────────────────
builder.Services.AddDbContextPool<AnMatesDbContext>(opt =>
{
    opt.UseNpgsql(
        builder.Configuration.GetConnectionString("Postgres"),
        npg => npg
            .UseNetTopologySuite()
            .EnableRetryOnFailure(maxRetryCount: 3, maxRetryDelay: TimeSpan.FromSeconds(2), errorCodesToAdd: null)
            .CommandTimeout(15));
    if (builder.Environment.IsDevelopment())
        opt.EnableSensitiveDataLogging();
});

// ── Identity ─────────────────────────────────────────────────────────────
builder.Services
    .AddIdentityCore<ApplicationUser>(o =>
    {
        o.Password.RequiredLength = 10;
        o.Password.RequireNonAlphanumeric = false;
        o.Lockout.MaxFailedAccessAttempts = 8;
        o.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
        o.User.RequireUniqueEmail = true;
        o.SignIn.RequireConfirmedEmail = false;
    })
    .AddRoles<ApplicationRole>()
    .AddEntityFrameworkStores<AnMatesDbContext>()
    .AddDefaultTokenProviders();

// ── JWT ──────────────────────────────────────────────────────────────────
var jwtKey = builder.Configuration["Jwt:SigningKey"]
    ?? throw new InvalidOperationException("Jwt:SigningKey is not configured.");
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "anmates";
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? "anmates-mobile";

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(o =>
    {
        o.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwtIssuer,
            ValidateAudience = true,
            ValidAudience = jwtAudience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromSeconds(30),
        };
        // SignalR sends the token in a `access_token` query param on websocket negotiate.
        o.Events = new JwtBearerEvents
        {
            OnMessageReceived = ctx =>
            {
                var token = ctx.Request.Query["access_token"];
                var path = ctx.HttpContext.Request.Path;
                if (!string.IsNullOrEmpty(token) && path.StartsWithSegments("/hubs"))
                    ctx.Token = token;
                return Task.CompletedTask;
            },
        };
    });
builder.Services.AddAuthorization();

// ── Redis (cache, rate-limit state, SignalR backplane) ───────────────────
var redisConn = builder.Configuration.GetConnectionString("Redis")
    ?? throw new InvalidOperationException("ConnectionStrings:Redis is not configured.");
var multiplexer = await ConnectionMultiplexer.ConnectAsync(redisConn);
builder.Services.AddSingleton<IConnectionMultiplexer>(multiplexer);

// ── Identity module services ──────────────────────────────────────────────
builder.Services
    .AddOptions<TokenServiceOptions>()
    .Bind(builder.Configuration.GetSection(TokenServiceOptions.SectionName))
    .ValidateOnStart();
builder.Services.AddScoped<ITokenService, TokenService>();

// ── Rate limiting (must register before SignalR so /hubs is also covered) ─
builder.Services.AddRedisRateLimiting(builder.Configuration);

// ── SignalR with Redis backplane ─────────────────────────────────────────
builder.Services
    .AddSignalR(o =>
    {
        o.EnableDetailedErrors = builder.Environment.IsDevelopment();
        o.MaximumReceiveMessageSize = 32 * 1024; // 32 KB / message — chat is small
        o.KeepAliveInterval = TimeSpan.FromSeconds(15);
        o.ClientTimeoutInterval = TimeSpan.FromSeconds(60);
    })
    .AddStackExchangeRedis(redisConn, o => o.Configuration.ChannelPrefix = RedisChannel.Literal("anmates-sr"));

// ── Misc ─────────────────────────────────────────────────────────────────
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHealthChecks()
    .AddDbContextCheck<AnMatesDbContext>("postgres")
    .AddRedis(redisConn, name: "redis");
builder.Services.AddProblemDetails();

builder.WebHost.ConfigureKestrel(o =>
{
    o.AddServerHeader = false;
    o.Limits.MaxRequestBodySize = 16 * 1024 * 1024; // 16 MB (avatar / check-in photo)
});

var app = builder.Build();

// ── Startup tasks ────────────────────────────────────────────────────────
await using (var scope = app.Services.CreateAsyncScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AnMatesDbContext>();

    // Apply any pending migrations automatically on startup.
    // Safe: uses an advisory lock so only one pod runs it in multi-replica setups.
    await db.Database.MigrateAsync();

    // Purge expired/revoked refresh tokens older than 30 days.
    var tokenSvc = scope.ServiceProvider.GetRequiredService<ITokenService>();
    await tokenSvc.PurgeExpiredTokensAsync(retentionDays: 30);
}

// ── Pipeline ─────────────────────────────────────────────────────────────
app.UseForwardedHeaders();
app.UseSerilogRequestLogging();
app.UseExceptionHandler();
app.UseStatusCodePages();

// Rate limit BEFORE auth resolution would only key by IP; routing must happen
// first so we know the endpoint, and auth must run so we can key by user id.
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();
app.UseRedisRateLimiting();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapHealthChecks("/health");
app.MapHealthChecks("/ready");
app.MapControllers();
// app.MapHub<ChatHub>("/hubs/chat");   // wired up in Chat module (next sprint)

app.Run();
