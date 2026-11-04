using CoupleApp.Domain.Cycles;

namespace CoupleApp.API.Contracts;

public sealed record SaveCycleProfileRequest(bool? TrackingEnabled, string? Visibility = null,
    int AverageCycleLength = 0, int AveragePeriodLength = 0, string? ExpectedPartnerCode = null,
    bool SettingsOnly = false, bool SharingOnly = false, bool TrackingOnly = false);
public sealed record SavePeriodRequest(DateOnly StartDate, DateOnly? EndDate,
    string? FlowLevel, int? PainLevel, string? Notes, Guid? ExpectedVersion = null);
public sealed record PeriodResponse(Guid Id, DateOnly StartDate, DateOnly? EndDate,
    string FlowLevel, int? PainLevel, string? Notes, DateTimeOffset CreatedAt, DateTimeOffset UpdatedAt, Guid Version);
public sealed record CycleSnapshot(bool TrackingEnabled, string Visibility,
    int AverageCycleLength, int AveragePeriodLength, IReadOnlyList<PeriodResponse> Periods,
    CycleEstimate? Prediction);
