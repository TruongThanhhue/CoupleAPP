using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using CoupleApp.API.Contracts;
using CoupleApp.API.Data;
using CoupleApp.Domain.Workspace;
using Microsoft.EntityFrameworkCore;

namespace CoupleApp.API.Endpoints;

public static class WorkspaceEndpoints
{
    public static void MapWorkspaceEndpoints(this WebApplication app)
    {
        var tasks = app.MapGroup("/api/v1/tasks").RequireAuthorization().WithTags("Tasks");
        tasks.AddEndpointFilter(AccountWriteLock.Filter);
        tasks.MapGet("", ListTasks);
        tasks.MapPost("", CreateTask);
        tasks.MapPut("/{id:guid}", UpdateTask);
        tasks.MapDelete("/{id:guid}", DeleteTask);

        var events = app.MapGroup("/api/v1/events").RequireAuthorization().WithTags("Calendar");
        events.AddEndpointFilter(AccountWriteLock.Filter);
        events.MapGet("", ListEvents);
        events.MapPost("", CreateEvent);
        events.MapPut("/{id:guid}", UpdateEvent);
        events.MapDelete("/{id:guid}", DeleteEvent);
        app.MapGet("/api/v1/home", Home).RequireAuthorization().WithTags("Home");
    }

    private static async Task<IResult> ListTasks(ClaimsPrincipal principal, CoupleDbContext db)
    {
        var viewer = await GetViewer(principal, db);
        if (viewer is null) return Results.Unauthorized();
        var items = await VisibleTasks(db, viewer).AsNoTracking().OrderBy(item => item.IsComplete)
            .ThenBy(item => item.DueAt == null).ThenBy(item => item.DueAt)
            .ThenByDescending(item => item.CreatedAt).ToListAsync();
        return Results.Ok(items.Select(item => ToResponse(item, viewer.Id)));
    }

    private static async Task<IResult> CreateTask(SaveTaskRequest request, ClaimsPrincipal principal, CoupleDbContext db)
    {
        var viewer = await GetViewer(principal, db);
        if (viewer is null) return Results.Unauthorized();
        var errors = WorkspaceValidation.Validate(request);
        if (errors.Count > 0) return Results.ValidationProblem(errors);
        if (request.IsShared && viewer.PartnerId is null) return MissingPartner();

        var item = new WorkspaceTask
        {
            Id = Guid.NewGuid(), OwnerId = viewer.Id,
            SharedWithUserId = request.IsShared ? viewer.PartnerId : null,
            Title = request.Title!.Trim(), Notes = Clean(request.Notes),
            IsComplete = request.IsComplete, Priority = request.Priority!,
            DueAt = request.DueAt?.ToUniversalTime(),
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow,
        };
        db.Tasks.Add(item);
        await db.SaveChangesAsync();
        return Results.Created($"/api/v1/tasks/{item.Id}", ToResponse(item, viewer.Id));
    }

    private static async Task<IResult> UpdateTask(Guid id, SaveTaskRequest request, ClaimsPrincipal principal, CoupleDbContext db)
    {
        var viewer = await GetViewer(principal, db);
        if (viewer is null) return Results.Unauthorized();
        var item = await db.Tasks.FindAsync(id);
        if (item is null || !WorkspaceAccess.CanRead(viewer.Id, item.OwnerId, item.SharedWithUserId, viewer.PartnerId))
            return Results.NotFound();
        var errors = WorkspaceValidation.Validate(request);
        if (errors.Count > 0) return Results.ValidationProblem(errors);
        var sharingError = CheckSharing(viewer, item.OwnerId, item.SharedWithUserId, request.IsShared);
        if (sharingError is not null) return sharingError;

        item.Title = request.Title!.Trim();
        item.Notes = Clean(request.Notes);
        item.IsComplete = request.IsComplete;
        item.Priority = request.Priority!;
        item.DueAt = request.DueAt?.ToUniversalTime();
        // A partner can edit the content, but only the owner can choose who receives it.
        if (item.OwnerId == viewer.Id) item.SharedWithUserId = request.IsShared ? viewer.PartnerId : null;
        item.UpdatedAt = DateTimeOffset.UtcNow;
        try { await db.SaveChangesAsync(); }
        catch (DbUpdateConcurrencyException) { return Changed(); }
        return Results.Ok(ToResponse(item, viewer.Id));
    }

    private static async Task<IResult> DeleteTask(Guid id, ClaimsPrincipal principal, CoupleDbContext db)
    {
        var viewer = await GetViewer(principal, db);
        if (viewer is null) return Results.Unauthorized();
        var item = await db.Tasks.FindAsync(id);
        if (item is null || !WorkspaceAccess.CanRead(viewer.Id, item.OwnerId, item.SharedWithUserId, viewer.PartnerId))
            return Results.NotFound();
        db.Tasks.Remove(item);
        try { await db.SaveChangesAsync(); }
        catch (DbUpdateConcurrencyException) { return Changed(); }
        return Results.NoContent();
    }

    private static async Task<IResult> ListEvents(ClaimsPrincipal principal, CoupleDbContext db)
    {
        var viewer = await GetViewer(principal, db);
        if (viewer is null) return Results.Unauthorized();
        var items = await VisibleEvents(db, viewer).AsNoTracking().OrderBy(item => item.StartsAt)
            .ThenBy(item => item.Id).ToListAsync();
        return Results.Ok(items.Select(item => ToResponse(item, viewer.Id)));
    }

    private static async Task<IResult> CreateEvent(SaveEventRequest request, ClaimsPrincipal principal, CoupleDbContext db)
    {
        var viewer = await GetViewer(principal, db);
        if (viewer is null) return Results.Unauthorized();
        var errors = WorkspaceValidation.Validate(request);
        if (errors.Count > 0) return Results.ValidationProblem(errors);
        if (request.IsShared && viewer.PartnerId is null) return MissingPartner();

        var item = new CalendarEvent
        {
            Id = Guid.NewGuid(), OwnerId = viewer.Id,
            SharedWithUserId = request.IsShared ? viewer.PartnerId : null,
            Title = request.Title!.Trim(), Notes = Clean(request.Notes), Location = Clean(request.Location),
            StartsAt = request.StartsAt.ToUniversalTime(), EndsAt = request.EndsAt.ToUniversalTime(),
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow,
        };
        db.Events.Add(item);
        await db.SaveChangesAsync();
        return Results.Created($"/api/v1/events/{item.Id}", ToResponse(item, viewer.Id));
    }

    private static async Task<IResult> UpdateEvent(Guid id, SaveEventRequest request, ClaimsPrincipal principal, CoupleDbContext db)
    {
        var viewer = await GetViewer(principal, db);
        if (viewer is null) return Results.Unauthorized();
        var item = await db.Events.FindAsync(id);
        if (item is null || !WorkspaceAccess.CanRead(viewer.Id, item.OwnerId, item.SharedWithUserId, viewer.PartnerId))
            return Results.NotFound();
        var errors = WorkspaceValidation.Validate(request);
        if (errors.Count > 0) return Results.ValidationProblem(errors);
        var sharingError = CheckSharing(viewer, item.OwnerId, item.SharedWithUserId, request.IsShared);
        if (sharingError is not null) return sharingError;

        item.Title = request.Title!.Trim();
        item.Notes = Clean(request.Notes);
        item.Location = Clean(request.Location);
        item.StartsAt = request.StartsAt.ToUniversalTime();
        item.EndsAt = request.EndsAt.ToUniversalTime();
        if (item.OwnerId == viewer.Id) item.SharedWithUserId = request.IsShared ? viewer.PartnerId : null;
        item.UpdatedAt = DateTimeOffset.UtcNow;
        try { await db.SaveChangesAsync(); }
        catch (DbUpdateConcurrencyException) { return Changed(); }
        return Results.Ok(ToResponse(item, viewer.Id));
    }

    private static async Task<IResult> DeleteEvent(Guid id, ClaimsPrincipal principal, CoupleDbContext db)
    {
        var viewer = await GetViewer(principal, db);
        if (viewer is null) return Results.Unauthorized();
        var item = await db.Events.FindAsync(id);
        if (item is null || !WorkspaceAccess.CanRead(viewer.Id, item.OwnerId, item.SharedWithUserId, viewer.PartnerId))
            return Results.NotFound();
        db.Events.Remove(item);
        try { await db.SaveChangesAsync(); }
        catch (DbUpdateConcurrencyException) { return Changed(); }
        return Results.NoContent();
    }

    private static async Task<IResult> Home(ClaimsPrincipal principal, CoupleDbContext db)
    {
        var viewer = await GetViewer(principal, db);
        if (viewer is null) return Results.Unauthorized();
        var tasks = VisibleTasks(db, viewer);
        var totalTasks = await tasks.CountAsync();
        var completedTasks = await tasks.CountAsync(item => item.IsComplete);
        var now = DateTimeOffset.UtcNow;
        var upcomingEvents = await VisibleEvents(db, viewer).AsNoTracking()
            .Where(item => item.EndsAt >= now).OrderBy(item => item.StartsAt).Take(5).ToListAsync();
        return Results.Ok(new
        {
            completedTasks, totalTasks,
            upcomingEvents = upcomingEvents.Select(item => ToResponse(item, viewer.Id)),
        });
    }

    private static IQueryable<WorkspaceTask> VisibleTasks(CoupleDbContext db, Viewer viewer) =>
        db.Tasks.Where(item => item.OwnerId == viewer.Id ||
            (item.SharedWithUserId == viewer.Id && item.OwnerId == viewer.PartnerId));

    private static IQueryable<CalendarEvent> VisibleEvents(CoupleDbContext db, Viewer viewer) =>
        db.Events.Where(item => item.OwnerId == viewer.Id ||
            (item.SharedWithUserId == viewer.Id && item.OwnerId == viewer.PartnerId));

    private static async Task<Viewer?> GetViewer(ClaimsPrincipal principal, CoupleDbContext db)
    {
        if (!Guid.TryParse(principal.FindFirst(JwtRegisteredClaimNames.Sub)?.Value, out var id)) return null;
        var user = await db.Users.AsNoTracking().SingleOrDefaultAsync(item => item.Id == id);
        if (user is null) return null;
        var mutualPartner = user.PartnerId.HasValue && await db.Users.AsNoTracking()
            .AnyAsync(item => item.Id == user.PartnerId && item.PartnerId == user.Id);
        return new Viewer(user.Id, mutualPartner ? user.PartnerId : null);
    }

    private static IResult? CheckSharing(Viewer viewer, Guid ownerId, Guid? sharedWithId, bool requestedShared)
    {
        if (!WorkspaceAccess.CanChangeSharing(viewer.Id, ownerId, sharedWithId, requestedShared))
            return Results.Json(new { message = "Chỉ người tạo mới có thể đổi chế độ chia sẻ." }, statusCode: 403);
        if (requestedShared && viewer.PartnerId is null) return MissingPartner();
        // Re-pairing never silently transfers an old shared record to a new partner.
        if (viewer.Id == ownerId && requestedShared && sharedWithId.HasValue && sharedWithId != viewer.PartnerId)
            return Results.Conflict(new { message = "Hãy chuyển mục này về riêng tư trước khi chia sẻ với partner mới." });
        return null;
    }

    private static string? Clean(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    private static IResult MissingPartner() => Results.Conflict(new { message = "Hãy kết nối partner trước khi chia sẻ." });
    private static IResult Changed() => Results.Conflict(new { message = "Dữ liệu vừa thay đổi. Vui lòng tải lại." });
    private sealed record Viewer(Guid Id, Guid? PartnerId);

    private static TaskResponse ToResponse(WorkspaceTask item, Guid viewerId) => new(item.Id, item.Title,
        item.Notes, item.IsComplete, item.SharedWithUserId.HasValue, item.Priority, item.DueAt,
        item.CreatedAt, item.UpdatedAt, item.OwnerId == viewerId);
    private static EventResponse ToResponse(CalendarEvent item, Guid viewerId) => new(item.Id, item.Title,
        item.Notes, item.Location, item.StartsAt, item.EndsAt, item.SharedWithUserId.HasValue,
        item.CreatedAt, item.UpdatedAt, item.OwnerId == viewerId);
}
