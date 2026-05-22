using AnMates.Domain.Enums;

namespace AnMates.Domain.Entities;

// Single chat message inside a Match.  WeightScore feeds the Friendship Progress
// Bar — short "k", "ok", emoji-only messages are weighted lower than substantive
// content; calculation lives in the Chat module's MessageWeightCalculator.
public class ChatMessage
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid MatchId { get; set; }
    public Match Match { get; set; } = null!;

    public Guid SenderId { get; set; }
    public ApplicationUser Sender { get; set; } = null!;

    public ChatMessageType Type { get; set; } = ChatMessageType.Text;

    // For Text: the message body (capped at 4 KB).
    // For non-text: short caption or empty.
    public string Content { get; set; } = string.Empty;

    // Pointers into MinIO for non-text payloads.
    public string? MediaUrl { get; set; }
    public string? MediaMimeType { get; set; }
    public long? MediaSizeBytes { get; set; }

    // Quality weight for progress bar.  0.0 = noise (single emoji), 1.0 = substantive.
    public decimal WeightScore { get; set; } = 1m;

    public bool IsViewOnce { get; set; }
    public DateTimeOffset? ViewedAt { get; set; }

    public DateTimeOffset SentAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? EditedAt { get; set; }
    public DateTimeOffset? DeletedAt { get; set; }
}
