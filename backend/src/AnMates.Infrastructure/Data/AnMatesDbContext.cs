using AnMates.Domain.Entities;
using AnMates.Domain.Enums;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using NetTopologySuite.Geometries;

namespace AnMates.Infrastructure.Data;

public class AnMatesDbContext
    : IdentityDbContext<ApplicationUser, ApplicationRole, Guid>
{
    public AnMatesDbContext(DbContextOptions<AnMatesDbContext> options) : base(options) { }

    public DbSet<Place> Places => Set<Place>();
    public DbSet<FoodWishlistItem> WishlistItems => Set<FoodWishlistItem>();
    public DbSet<Match> Matches => Set<Match>();
    public DbSet<ChatMessage> ChatMessages => Set<ChatMessage>();
    public DbSet<DepositEscrow> DepositEscrows => Set<DepositEscrow>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.HasPostgresExtension("postgis");
        builder.HasPostgresExtension("pg_trgm");
        builder.HasPostgresExtension("pgcrypto");

        // ── ApplicationUser ───────────────────────────────────────────────
        builder.Entity<ApplicationUser>(e =>
        {
            e.ToTable("users");

            e.Property(u => u.DisplayName).HasMaxLength(80).IsRequired();
            e.Property(u => u.Bio).HasMaxLength(500);
            e.Property(u => u.AvatarUrl).HasMaxLength(500);
            e.Property(u => u.Gender).HasConversion<short>();
            e.Property(u => u.Personality).HasConversion<short>();
            e.Property(u => u.Intention).HasConversion<short>();

            e.Property(u => u.VibeTags).HasColumnType("text[]");
            e.Property(u => u.FoodPreferenceTags).HasColumnType("text[]");

            e.Property(u => u.TrustScore).HasColumnType("numeric(5,2)").HasDefaultValue(50m);

            e.Property(u => u.LastLocation)
             .HasColumnType("geography(Point, 4326)");

            // Spatial index — GIST is required for ST_DWithin / ST_Distance queries.
            e.HasIndex(u => u.LastLocation)
             .HasMethod("GIST")
             .HasDatabaseName("ix_users_last_location_gist");

            e.HasIndex(u => u.LastActiveAt).HasDatabaseName("ix_users_last_active_at");

            // GIN on tag arrays for "users sharing N tags" queries.
            e.HasIndex(u => u.VibeTags).HasMethod("GIN").HasDatabaseName("ix_users_vibe_tags_gin");
            e.HasIndex(u => u.FoodPreferenceTags).HasMethod("GIN").HasDatabaseName("ix_users_food_tags_gin");
        });

        // ── RefreshToken ──────────────────────────────────────────────────
        builder.Entity<RefreshToken>(e =>
        {
            e.ToTable("refresh_tokens");
            e.HasKey(r => r.Id);

            e.Property(r => r.TokenHash).HasMaxLength(88).IsRequired();   // base64(sha256) = 44 chars; 88 is safe
            e.Property(r => r.ReplacedByTokenHash).HasMaxLength(88);
            e.Property(r => r.RevokedReason).HasMaxLength(200);

            e.HasOne(r => r.User)
             .WithMany()
             .HasForeignKey(r => r.UserId)
             .OnDelete(DeleteBehavior.Cascade);

            // Lookup by hash on every authenticated request.
            e.HasIndex(r => r.TokenHash).IsUnique().HasDatabaseName("ux_refresh_token_hash");
            // Cleanup job walks this.
            e.HasIndex(r => new { r.UserId, r.ExpiresAt }).HasDatabaseName("ix_refresh_user_expires");
        });

        // ── Place ─────────────────────────────────────────────────────────
        builder.Entity<Place>(e =>
        {
            e.ToTable("places");
            e.HasKey(p => p.Id);

            e.Property(p => p.Name).HasMaxLength(160).IsRequired();
            e.Property(p => p.Description).HasMaxLength(2000);
            e.Property(p => p.Address).HasMaxLength(400);
            e.Property(p => p.Category).HasMaxLength(40).IsRequired();
            e.Property(p => p.PriceRange).HasMaxLength(8);
            e.Property(p => p.AverageRating).HasColumnType("numeric(3,2)");

            e.Property(p => p.Location)
             .HasColumnType("geography(Point, 4326)")
             .IsRequired();

            e.Property(p => p.VibeTags).HasColumnType("text[]");
            e.Property(p => p.CuisineTags).HasColumnType("text[]");
            e.Property(p => p.PhotoUrls).HasColumnType("text[]");
            e.Property(p => p.OperatingHoursJson).HasColumnType("jsonb");

            e.HasIndex(p => p.Location)
             .HasMethod("GIST")
             .HasDatabaseName("ix_places_location_gist");

            // Trigram index for "Quán phở..." substring search.
            e.HasIndex(p => p.Name)
             .HasMethod("GIN")
             .HasOperators("gin_trgm_ops")
             .HasDatabaseName("ix_places_name_trgm");

            e.HasIndex(p => p.VibeTags).HasMethod("GIN").HasDatabaseName("ix_places_vibe_tags_gin");
            e.HasIndex(p => p.CuisineTags).HasMethod("GIN").HasDatabaseName("ix_places_cuisine_tags_gin");
        });

        // ── FoodWishlistItem ──────────────────────────────────────────────
        builder.Entity<FoodWishlistItem>(e =>
        {
            e.ToTable("food_wishlist_items");
            e.HasKey(w => w.Id);

            e.Property(w => w.PlaceName).HasMaxLength(160).IsRequired();
            e.Property(w => w.Note).HasMaxLength(400);
            e.Property(w => w.Status).HasConversion<short>();

            e.Property(w => w.Location)
             .HasColumnType("geography(Point, 4326)")
             .IsRequired();

            e.HasOne(w => w.User)
             .WithMany(u => u.WishlistItems)
             .HasForeignKey(w => w.UserId)
             .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(w => w.Place)
             .WithMany()
             .HasForeignKey(w => w.PlaceId)
             .OnDelete(DeleteBehavior.SetNull);

            // Composite index drives the dominant matching query:
            // "find users with status=LookingForCompanion whose item is close to mine".
            e.HasIndex(w => new { w.Status, w.UserId })
             .HasDatabaseName("ix_wishlist_status_user");

            e.HasIndex(w => w.Location)
             .HasMethod("GIST")
             .HasDatabaseName("ix_wishlist_location_gist");

            // Place co-attendance lookups.
            e.HasIndex(w => new { w.PlaceId, w.Status })
             .HasFilter("\"PlaceId\" IS NOT NULL")
             .HasDatabaseName("ix_wishlist_place_status");
        });

        // ── Match ─────────────────────────────────────────────────────────
        builder.Entity<Match>(e =>
        {
            e.ToTable("matches", t =>
            {
                // Invariant: ordered pair, one row per couple.
                t.HasCheckConstraint("ck_matches_ordered_pair", "\"UserAId\" < \"UserBId\"");
                t.HasCheckConstraint("ck_matches_progress_range", "\"FriendshipProgress\" BETWEEN 0 AND 100");
                t.HasCheckConstraint("ck_matches_vibe_range", "\"VibeScore\" BETWEEN 0 AND 100");
            });

            e.HasKey(m => m.Id);

            e.Property(m => m.Mode).HasConversion<short>();
            e.Property(m => m.Status).HasConversion<short>();
            e.Property(m => m.VibeScore).HasColumnType("numeric(5,2)");
            e.Property(m => m.SharedWishlistItemIds).HasColumnType("uuid[]");

            e.HasOne(m => m.UserA)
             .WithMany()
             .HasForeignKey(m => m.UserAId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(m => m.UserB)
             .WithMany()
             .HasForeignKey(m => m.UserBId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasIndex(m => new { m.UserAId, m.UserBId })
             .IsUnique()
             .HasDatabaseName("ux_matches_pair");

            // "Show me my active matches" — partial index keeps it tiny.
            e.HasIndex(m => new { m.UserAId, m.Status, m.LastMessageAt })
             .HasDatabaseName("ix_matches_usera_status_lastmsg");
            e.HasIndex(m => new { m.UserBId, m.Status, m.LastMessageAt })
             .HasDatabaseName("ix_matches_userb_status_lastmsg");
        });

        // ── ChatMessage ───────────────────────────────────────────────────
        builder.Entity<ChatMessage>(e =>
        {
            e.ToTable("chat_messages");
            e.HasKey(c => c.Id);

            e.Property(c => c.Type).HasConversion<short>();
            e.Property(c => c.Content).HasMaxLength(4096).IsRequired();
            e.Property(c => c.MediaUrl).HasMaxLength(500);
            e.Property(c => c.MediaMimeType).HasMaxLength(80);
            e.Property(c => c.WeightScore).HasColumnType("numeric(4,2)").HasDefaultValue(1m);

            e.HasOne(c => c.Match)
             .WithMany(m => m.Messages)
             .HasForeignKey(c => c.MatchId)
             .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(c => c.Sender)
             .WithMany()
             .HasForeignKey(c => c.SenderId)
             .OnDelete(DeleteBehavior.Restrict);

            // The hot path: page chat by Match newest-first.
            e.HasIndex(c => new { c.MatchId, c.SentAt })
             .IsDescending(false, true)
             .HasDatabaseName("ix_chat_match_sent_desc");
        });

        // ── DepositEscrow ─────────────────────────────────────────────────
        builder.Entity<DepositEscrow>(e =>
        {
            e.ToTable("deposit_escrows", t =>
            {
                t.HasCheckConstraint("ck_escrow_amount_positive",
                    "\"AmountPerSide\" > 0 AND \"PoolAmount\" >= \"AmountPerSide\" * 2");
            });

            e.HasKey(d => d.Id);
            e.Property(d => d.Status).HasConversion<short>();
            e.Property(d => d.UserAProvider).HasConversion<short?>();
            e.Property(d => d.UserBProvider).HasConversion<short?>();
            e.Property(d => d.VenueName).HasMaxLength(160).IsRequired();
            e.Property(d => d.UserATransactionId).HasMaxLength(80);
            e.Property(d => d.UserBTransactionId).HasMaxLength(80);
            e.Property(d => d.UserACheckInPhotoUrl).HasMaxLength(500);
            e.Property(d => d.UserBCheckInPhotoUrl).HasMaxLength(500);
            e.Property(d => d.ResolutionNotes).HasMaxLength(2000);

            e.Property(d => d.UserACheckInLocation).HasColumnType("geography(Point, 4326)");
            e.Property(d => d.UserBCheckInLocation).HasColumnType("geography(Point, 4326)");

            e.HasOne(d => d.Match)
             .WithMany()
             .HasForeignKey(d => d.MatchId)
             .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(d => d.Venue)
             .WithMany()
             .HasForeignKey(d => d.VenueId)
             .OnDelete(DeleteBehavior.SetNull);

            e.HasIndex(d => d.MatchId).HasDatabaseName("ix_escrow_match");

            // Scheduler walks this every minute to fire reminders & timeouts.
            e.HasIndex(d => new { d.Status, d.ScheduledAt })
             .HasDatabaseName("ix_escrow_status_scheduled");

            // Unique provider transaction ids — defends against webhook replays.
            e.HasIndex(d => d.UserATransactionId)
             .IsUnique()
             .HasFilter("\"UserATransactionId\" IS NOT NULL")
             .HasDatabaseName("ux_escrow_usera_tx");
            e.HasIndex(d => d.UserBTransactionId)
             .IsUnique()
             .HasFilter("\"UserBTransactionId\" IS NOT NULL")
             .HasDatabaseName("ux_escrow_userb_tx");
        });
    }
}
