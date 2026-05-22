using AnMates.Domain.Enums;
using NetTopologySuite.Geometries;

namespace AnMates.Domain.Entities;

// Escrow record for a planned meet.  AnMates never holds funds directly — MoMo /
// ZaloPay are the licensed escrow agents.  This row tracks state machine, photo
// proofs, and which side has funded / checked in.
public class DepositEscrow
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid MatchId { get; set; }
    public Match Match { get; set; } = null!;

    // Both sides snapshotted from Match.UserA/UserB at creation.
    public Guid UserAId { get; set; }
    public Guid UserBId { get; set; }

    // Money in minor units (đồng).  20_000 ₫ per side, 40_000 ₫ pool.
    public int AmountPerSide { get; set; } = 20_000;
    public int PoolAmount { get; set; } = 40_000;
    public int PlatformFeeOnNoShow { get; set; } = 10_000;

    public PaymentProvider? UserAProvider { get; set; }
    public PaymentProvider? UserBProvider { get; set; }
    public string? UserATransactionId { get; set; }
    public string? UserBTransactionId { get; set; }
    public DateTimeOffset? UserAFundedAt { get; set; }
    public DateTimeOffset? UserBFundedAt { get; set; }

    // Venue & schedule.
    public Guid? VenueId { get; set; }
    public Place? Venue { get; set; }
    public string VenueName { get; set; } = string.Empty;
    public DateTimeOffset ScheduledAt { get; set; }

    public EscrowStatus Status { get; set; } = EscrowStatus.AwaitingFunding;

    // Check-in proof at meet time.
    public string? UserACheckInPhotoUrl { get; set; }
    public Point? UserACheckInLocation { get; set; }
    public DateTimeOffset? UserACheckInAt { get; set; }

    public string? UserBCheckInPhotoUrl { get; set; }
    public Point? UserBCheckInLocation { get; set; }
    public DateTimeOffset? UserBCheckInAt { get; set; }

    public string? ResolutionNotes { get; set; }
    public Guid? ResolvedByAdminId { get; set; }
    public DateTimeOffset? ResolvedAt { get; set; }

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? UpdatedAt { get; set; }
}
