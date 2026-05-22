namespace AnMates.Domain.Enums;

public enum Gender
{
    Unspecified = 0,
    Male = 1,
    Female = 2,
    NonBinary = 3,
    Other = 99,
}

public enum Personality
{
    Unspecified = 0,
    Introvert = 1,
    Extrovert = 2,
    Ambivert = 3,
}

public enum Intention
{
    Friendship = 1,
    Dating = 2,
    Both = 3,
}

public enum WishlistStatus
{
    LookingForCompanion = 1,
    SoloOk = 2,
    Done = 3,
    Archived = 99,
}

public enum MatchMode
{
    RandomVibe = 1,
    ActivityFood = 2,
    GroupHangout = 3,
    DateMode = 4,
}

public enum MatchStatus
{
    Pending = 1,
    Active = 2,
    InviteSent = 3,
    Scheduled = 4,
    Completed = 5,
    Expired = 90,
    Blocked = 99,
}

public enum ChatMessageType
{
    Text = 1,
    Voice = 2,
    Image = 3,
    Sticker = 4,
    LocationShare = 5,
    InvitationCard = 10,
    System = 99,
}

public enum EscrowStatus
{
    AwaitingFunding = 1,
    Locked = 2,
    MeetingConfirmed = 3,
    NoShowSingle = 4,
    NoShowBoth = 5,
    Disputed = 6,
    Refunded = 7,
    Resolved = 99,
}

public enum PaymentProvider
{
    MoMo = 1,
    ZaloPay = 2,
}
