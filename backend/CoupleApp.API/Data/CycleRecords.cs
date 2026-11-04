using CoupleApp.Domain.Cycles;

namespace CoupleApp.API.Data;

public sealed class CycleProfile
{
    public Guid UserId { get; set; }
    public bool TrackingEnabled { get; set; }
    public CycleVisibility Visibility { get; set; }
    public Guid? SharedWithUserId { get; set; }
    public int AverageCycleLength { get; set; } = 28;
    public int AveragePeriodLength { get; set; } = 5;
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
}

public sealed class PeriodEntry
{
    public Guid Id { get; set; }
    public Guid Version { get; set; }
    public Guid UserId { get; set; }
    public DateOnly StartDate { get; set; }
    public DateOnly? EndDate { get; set; }
    public required string FlowLevel { get; set; }
    public int? PainLevel { get; set; }
    public string? Notes { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
}

public sealed class CyclePredictionRecord
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public DateOnly AnchorStart { get; set; }
    public DateOnly ExpectedStart { get; set; }
    public DateOnly EarliestStart { get; set; }
    public DateOnly LatestStart { get; set; }
    public required string Basis { get; set; }
    public int IntervalCount { get; set; }
    public required string AlgorithmVersion { get; set; }
    public DateTimeOffset GeneratedAt { get; set; }
    public DateOnly? ActualStart { get; set; }
    public int? ErrorDays { get; set; }
}
