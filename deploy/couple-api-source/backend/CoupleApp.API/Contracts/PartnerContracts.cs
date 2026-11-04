namespace CoupleApp.API.Contracts;

public sealed record SendPartnerInviteRequest(string PartnerCode);
public sealed record PartnerInviteResponse(Guid Id, string FromDisplayName, string Status, DateTimeOffset CreatedAt);
public sealed record SentPartnerInviteResponse(Guid Id, string ToDisplayName, DateTimeOffset CreatedAt);
