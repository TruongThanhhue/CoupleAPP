namespace CoupleApp.API.Contracts;

public sealed record RegisterRequest(string Email, string Password, string DisplayName);
public sealed record LoginRequest(string Email, string Password);
public sealed record AuthResponse(string AccessToken, UserProfile User);
public sealed record UserProfile(string DisplayName, string PartnerCode, PartnerProfile? Partner);
public sealed record PartnerProfile(string DisplayName, string PartnerCode);
public sealed record UpdateProfileRequest(string? DisplayName);
public sealed record DisconnectPartnerRequest(string? PartnerCode);
