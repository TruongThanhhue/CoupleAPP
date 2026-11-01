namespace CoupleApp.API.Data;

public sealed class WorkspaceTask
{
    public Guid Id { get; set; }
    public Guid OwnerId { get; set; }
    public Guid? SharedWithUserId { get; set; }
    public required string Title { get; set; }
    public string? Notes { get; set; }
    public bool IsComplete { get; set; }
    public required string Priority { get; set; }
    public DateTimeOffset? DueAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
}

public sealed class CalendarEvent
{
    public Guid Id { get; set; }
    public Guid OwnerId { get; set; }
    public Guid? SharedWithUserId { get; set; }
    public required string Title { get; set; }
    public string? Notes { get; set; }
    public string? Location { get; set; }
    public DateTimeOffset StartsAt { get; set; }
    public DateTimeOffset EndsAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
}
