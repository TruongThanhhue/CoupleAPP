namespace CoupleApp.Application.Home;

public sealed record DashboardSummary(
    string CoupleName,
    int DaysTogether,
    int CompletedTasks,
    int TotalTasks,
    IReadOnlyList<DashboardEvent> TodayEvents,
    PartnerLocationStatus PartnerLocation);

public sealed record DashboardEvent(string Title, DateTimeOffset StartsAt, string? Place);

public sealed record PartnerLocationStatus(bool IsSharing, string? Label, DateTimeOffset? UpdatedAt);

public interface IDashboardQuery
{
    DashboardSummary GetDemo();
}

/// <summary>
/// A deliberately static implementation which makes the mobile API contract
/// testable before authentication and persistence are introduced.
/// </summary>
public sealed class DemoDashboardQuery : IDashboardQuery
{
    public DashboardSummary GetDemo()
    {
        var now = DateTimeOffset.UtcNow;
        return new DashboardSummary(
            CoupleName: "Minh & An",
            DaysTogether: 1248,
            CompletedTasks: 3,
            TotalTasks: 5,
            TodayEvents:
            [
                new DashboardEvent("Dinner together", now.Date.AddHours(12), "Bếp nhà mình"),
            ],
            PartnerLocation: new PartnerLocationStatus(
                IsSharing: false,
                Label: null,
                UpdatedAt: null));
    }
}
