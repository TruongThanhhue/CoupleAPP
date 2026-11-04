using CoupleApp.Domain.Cycles;

namespace CoupleApp.Domain.Tests.Cycles;

public class CycleEstimatorTests
{
    [Fact]
    public void EmptyHistoryHasNoPrediction() =>
        Assert.Null(CycleEstimator.Estimate([], 28));

    [Fact]
    public void SingleStartUsesConfiguredLengthWithoutClaimingHistoricalEvidence()
    {
        var prediction = CycleEstimator.Estimate([new DateOnly(2026, 1, 1)], 31)!;
        Assert.Equal(new DateOnly(2026, 2, 1), prediction.ExpectedStart);
        Assert.Equal(prediction.ExpectedStart, prediction.EarliestStart);
        Assert.Equal(prediction.ExpectedStart, prediction.LatestStart);
        Assert.Equal("profile", prediction.Basis);
        Assert.Equal(0, prediction.IntervalCount);
    }

    [Fact]
    public void UsesMeanAndObservedRangeOfActualStartIntervals()
    {
        var start = new DateOnly(2026, 1, 1);
        var prediction = CycleEstimator.Estimate([start, start.AddDays(26), start.AddDays(56)], 100)!;
        Assert.Equal(start.AddDays(84), prediction.ExpectedStart);
        Assert.Equal(start.AddDays(82), prediction.EarliestStart);
        Assert.Equal(start.AddDays(86), prediction.LatestStart);
        Assert.Equal("history", prediction.Basis);
        Assert.Equal(2, prediction.IntervalCount);
    }

    [Fact]
    public void SortsAndDeduplicatesBeforeCountingIntervals()
    {
        var start = new DateOnly(2026, 1, 1);
        var prediction = CycleEstimator.Estimate([start.AddDays(29), start, start.AddDays(29)], 28)!;
        Assert.Equal(start.AddDays(58), prediction.ExpectedStart);
        Assert.Equal(1, prediction.IntervalCount);
    }

    [Fact]
    public void UsesOnlySixMostRecentIntervals()
    {
        var start = new DateOnly(2026, 1, 1);
        // The initial 60-day gap must not influence the latest six 28-day gaps.
        var starts = new[] { start }.Concat(Enumerable.Range(0, 7).Select(index => start.AddDays(60 + index * 28)));
        var prediction = CycleEstimator.Estimate(starts, 40)!;
        Assert.Equal(start.AddDays(256), prediction.ExpectedStart);
        Assert.Equal(prediction.ExpectedStart, prediction.EarliestStart);
        Assert.Equal(prediction.ExpectedStart, prediction.LatestStart);
        Assert.Equal(6, prediction.IntervalCount);
    }

    [Fact]
    public void HalfDayMeanRoundsForwardDeterministically()
    {
        var start = new DateOnly(2026, 1, 1);
        var prediction = CycleEstimator.Estimate([start, start.AddDays(28), start.AddDays(57)], 28)!;
        Assert.Equal(start.AddDays(86), prediction.ExpectedStart);
    }

    [Fact]
    public void CalendarAdditionHandlesLeapYears()
    {
        var prediction = CycleEstimator.Estimate([new DateOnly(2024, 2, 1)], 28)!;
        Assert.Equal(new DateOnly(2024, 2, 29), prediction.ExpectedStart);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    [InlineData(121)]
    public void RejectsInvalidConfiguredLength(int length) =>
        Assert.Throws<ArgumentOutOfRangeException>(() => CycleEstimator.Estimate([], length));
}
