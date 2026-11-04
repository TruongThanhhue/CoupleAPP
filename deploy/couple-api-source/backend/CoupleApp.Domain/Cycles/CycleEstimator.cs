namespace CoupleApp.Domain.Cycles;

public sealed record CycleEstimate(DateOnly ExpectedStart, DateOnly EarliestStart,
    DateOnly LatestStart, string Basis, int IntervalCount);

/// <summary>Descriptive dates from recorded start intervals, not clinical probabilities.</summary>
public static class CycleEstimator
{
    public const string Version = "mean-last-six-v1";

    public static CycleEstimate? Estimate(IEnumerable<DateOnly> recordedStarts, int configuredLength)
    {
        if (configuredLength is < 1 or > 120) throw new ArgumentOutOfRangeException(nameof(configuredLength));
        var starts = recordedStarts.Distinct().Order().TakeLast(7).ToArray();
        if (starts.Length == 0) return null;
        var anchor = starts[^1];
        var intervals = starts.Zip(starts.Skip(1), (a, b) => b.DayNumber - a.DayNumber).ToArray();
        if (intervals.Length == 0)
        {
            var date = anchor.AddDays(configuredLength);
            return new(date, date, date, "profile", 0);
        }
        var mean = (int)Math.Round(intervals.Average(), MidpointRounding.AwayFromZero);
        return new(anchor.AddDays(mean), anchor.AddDays(intervals.Min()),
            anchor.AddDays(intervals.Max()), "history", intervals.Length);
    }
}
