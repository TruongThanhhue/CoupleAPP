using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using CoupleApp.API.Contracts;
using CoupleApp.API.Data;
using CoupleApp.Domain.Cycles;
using Microsoft.EntityFrameworkCore;

namespace CoupleApp.API.Endpoints;

public static class CycleEndpoints
{
    public static void MapCycleEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/v1/cycles").RequireAuthorization().WithTags("Cycles");
        group.AddEndpointFilter(AccountWriteLock.Filter);
        group.MapGet("/me", Me);
        group.MapGet("/partner", Partner);
        group.MapGet("/history", History);
        group.MapPut("/profile", SaveProfile);
        group.MapPost("/periods", CreatePeriod);
        group.MapPut("/periods/{id:guid}", UpdatePeriod);
        group.MapDelete("/periods/{id:guid}", DeletePeriod);
    }

    private static async Task<IResult> Me(ClaimsPrincipal principal, CoupleDbContext db)
    {
        var user = await CurrentUser(principal, db);
        if (user is null) return Results.Unauthorized();
        return Results.Ok(await Snapshot(db, user.Id, false));
    }

    private static async Task<IResult> Partner(ClaimsPrincipal principal, CoupleDbContext db)
    {
        var viewer = await CurrentUser(principal, db);
        if (viewer is null) return Results.Unauthorized();
        if (viewer.PartnerId is not { } ownerId) return Hidden();
        // Sharing changes use the owner's lock; disconnect uses both accounts.
        // Re-read membership/consent after the lock to avoid stale authorization.
        await using var transaction = await AccountWriteLock.BeginAsync(db, viewer.Id, ownerId);
        var mutual = await db.Users.AsNoTracking().AnyAsync(user => user.Id == viewer.Id && user.PartnerId == ownerId)
            && await db.Users.AsNoTracking().AnyAsync(user => user.Id == ownerId && user.PartnerId == viewer.Id);
        var permitted = mutual && await db.CycleProfiles.AsNoTracking().AnyAsync(profile => profile.UserId == ownerId &&
            profile.TrackingEnabled && profile.Visibility == CycleVisibility.Partner && profile.SharedWithUserId == viewer.Id);
        if (!permitted) return Hidden();
        var result = await Snapshot(db, ownerId, true);
        await transaction.CommitAsync();
        return Results.Ok(result);
    }

    private static async Task<IResult> History(ClaimsPrincipal principal, CoupleDbContext db)
    {
        var user = await CurrentUser(principal, db);
        if (user is null) return Results.Unauthorized();
        var history = await db.CyclePredictions.AsNoTracking().Where(item => item.UserId == user.Id)
            .OrderByDescending(item => item.GeneratedAt).Take(100)
            .Select(item => new { item.Id, item.AnchorStart, item.ExpectedStart, item.EarliestStart, item.LatestStart,
                item.Basis, item.IntervalCount, item.AlgorithmVersion, item.GeneratedAt, item.ActualStart, item.ErrorDays }).ToListAsync();
        return Results.Ok(history);
    }

    private static async Task<IResult> SaveProfile(SaveCycleProfileRequest request, ClaimsPrincipal principal, CoupleDbContext db)
    {
        var user = await CurrentUser(principal, db);
        if (user is null) return Results.Unauthorized();
        var profile = await db.CycleProfiles.FindAsync(user.Id);
        var fullUpdate = !request.TrackingOnly && !request.SettingsOnly && !request.SharingOnly;
        var writesTracking = fullUpdate || request.TrackingOnly;
        var writesSharing = fullUpdate || request.SharingOnly;
        // Legacy toggles sent a full cached profile. Keep current lengths when
        // changing tracking, even if an older device supplies stale values.
        var writesLengths = request.SettingsOnly || (fullUpdate && (profile is null ||
            (profile.TrackingEnabled && request.TrackingEnabled == true)));
        var errors = new Dictionary<string, string[]>();
        if ((request.TrackingOnly && (request.SettingsOnly || request.SharingOnly)) || (request.SettingsOnly && request.SharingOnly))
            errors["mode"] = ["Chỉ chọn một chế độ cập nhật."];
        if (writesTracking && request.TrackingEnabled is null)
            errors["trackingEnabled"] = ["Hãy chọn bật hoặc tắt theo dõi."];
        if (writesSharing && request.Visibility is not ("private" or "partner")) errors["visibility"] = ["Chế độ chia sẻ không hợp lệ."];
        if (writesLengths)
        {
            if (request.AverageCycleLength is < 1 or > 120) errors["averageCycleLength"] = ["Độ dài chu kỳ cần từ 1 đến 120 ngày."];
            if (request.AveragePeriodLength is < 1 or > 60 || request.AveragePeriodLength > request.AverageCycleLength)
                errors["averagePeriodLength"] = ["Độ dài kỳ cần từ 1 đến 60 ngày và không dài hơn chu kỳ."];
        }
        if (errors.Count > 0) return Results.ValidationProblem(errors);
        if (request.SettingsOnly && profile is null)
            return Results.Conflict(new { message = "Hãy thiết lập theo dõi chu kỳ trước khi sửa độ dài." });
        if (request.SharingOnly && (profile is null || !profile.TrackingEnabled))
            return Results.Conflict(new { message = "Theo dõi chu kỳ đang tắt. Hãy tải lại trước khi đổi quyền chia sẻ." });
        Guid? recipient = null;
        if (writesSharing && (request.SharingOnly || request.TrackingEnabled == true) && request.Visibility == "partner")
        {
            if (user.PartnerId is null || string.IsNullOrWhiteSpace(request.ExpectedPartnerCode) ||
                !await db.Users.AsNoTracking().AnyAsync(partner => partner.Id == user.PartnerId && partner.PartnerId == user.Id &&
                    partner.PartnerCode == request.ExpectedPartnerCode.Trim().ToUpperInvariant()))
                return Results.Conflict(new { message = "Partner đã thay đổi hoặc chưa kết nối. Hãy tải lại và xác nhận người được chia sẻ." });
            recipient = user.PartnerId;
        }
        if (profile is null)
        {
            profile = new CycleProfile { UserId = user.Id, CreatedAt = DateTimeOffset.UtcNow };
            db.CycleProfiles.Add(profile);
        }
        if (writesTracking) profile.TrackingEnabled = request.TrackingEnabled!.Value;
        if (writesSharing || (request.TrackingOnly && !profile.TrackingEnabled))
        {
            profile.Visibility = recipient.HasValue ? CycleVisibility.Partner : CycleVisibility.Private;
            profile.SharedWithUserId = recipient;
        }
        if (writesLengths)
        {
            profile.AverageCycleLength = request.AverageCycleLength;
            profile.AveragePeriodLength = request.AveragePeriodLength;
        }
        profile.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync();
        await RecordPrediction(db, profile);
        return Results.Ok(await Snapshot(db, user.Id, false));
    }

    private static Task<IResult> CreatePeriod(SavePeriodRequest request, ClaimsPrincipal principal, CoupleDbContext db) =>
        SavePeriod(null, request, principal, db);
    private static Task<IResult> UpdatePeriod(Guid id, SavePeriodRequest request, ClaimsPrincipal principal, CoupleDbContext db) =>
        SavePeriod(id, request, principal, db);

    private static async Task<IResult> SavePeriod(Guid? id, SavePeriodRequest request, ClaimsPrincipal principal, CoupleDbContext db)
    {
        var user = await CurrentUser(principal, db);
        if (user is null) return Results.Unauthorized();
        var entry = id.HasValue ? await db.PeriodEntries.SingleOrDefaultAsync(item => item.Id == id && item.UserId == user.Id) : null;
        if (id.HasValue && entry is null) return Results.NotFound();
        if (entry is not null && request.ExpectedVersion != entry.Version) return PeriodChanged();
        var profile = await db.CycleProfiles.FindAsync(user.Id);
        if (profile is null || !profile.TrackingEnabled)
            return Results.Conflict(new { message = "Hãy bật theo dõi chu kỳ trước khi ghi lại kỳ." });
        var errors = ValidatePeriod(request);
        if (errors.Count > 0) return Results.ValidationProblem(errors);
        var end = request.EndDate ?? DateOnly.MaxValue;
        var overlaps = await db.PeriodEntries.AnyAsync(item => item.UserId == user.Id && item.Id != id &&
            item.StartDate <= end && (item.EndDate == null || item.EndDate >= request.StartDate));
        if (overlaps) return Results.Conflict(new { message = "Khoảng ngày trùng với kỳ đã ghi. Hãy kết thúc kỳ đang mở hoặc sửa ngày." });
        if (entry is null)
        {
            entry = new PeriodEntry { Id = Guid.NewGuid(), UserId = user.Id, FlowLevel = request.FlowLevel!, CreatedAt = DateTimeOffset.UtcNow };
            db.PeriodEntries.Add(entry);
        }
        else if (entry.StartDate != request.StartDate)
        {
            await RemoveAnchoredPredictions(db, entry);
        }
        entry.StartDate = request.StartDate;
        entry.EndDate = request.EndDate;
        entry.FlowLevel = request.FlowLevel!;
        entry.PainLevel = request.PainLevel;
        entry.Notes = string.IsNullOrWhiteSpace(request.Notes) ? null : request.Notes.Trim();
        entry.UpdatedAt = DateTimeOffset.UtcNow;
        entry.Version = Guid.NewGuid();
        try { await db.SaveChangesAsync(); }
        catch (DbUpdateConcurrencyException) { return PeriodChanged(); }
        await RecordPrediction(db, profile);
        var result = await Snapshot(db, user.Id, false);
        return id is null ? Results.Created($"/api/v1/cycles/periods/{entry.Id}", result) : Results.Ok(result);
    }

    private static async Task<IResult> DeletePeriod(Guid id, Guid? expectedVersion, ClaimsPrincipal principal, CoupleDbContext db)
    {
        var user = await CurrentUser(principal, db);
        if (user is null) return Results.Unauthorized();
        var entry = await db.PeriodEntries.SingleOrDefaultAsync(item => item.Id == id && item.UserId == user.Id);
        if (entry is null) return Results.NotFound();
        if (entry.Version != expectedVersion) return PeriodChanged();
        await RemoveAnchoredPredictions(db, entry);
        db.PeriodEntries.Remove(entry);
        try { await db.SaveChangesAsync(); }
        catch (DbUpdateConcurrencyException) { return PeriodChanged(); }
        var profile = await db.CycleProfiles.FindAsync(user.Id);
        if (profile is not null) await RecordPrediction(db, profile);
        return Results.NoContent();
    }

    private static Task<int> RemoveAnchoredPredictions(CoupleDbContext db, PeriodEntry entry) =>
        db.CyclePredictions.Where(item => item.UserId == entry.UserId && item.AnchorStart == entry.StartDate).ExecuteDeleteAsync();

    private static IResult PeriodChanged() => Results.Conflict(new
    {
        code = "cycle_period_changed",
        message = "Hãy tải bản mới của kỳ trước khi sửa hoặc xóa."
    });

    private static Dictionary<string, string[]> ValidatePeriod(SavePeriodRequest request)
    {
        var errors = new Dictionary<string, string[]>();
        var first = new DateOnly(2000, 1, 1);
        // Date-only input can be tomorrow in UTC+14; no time-of-day is recorded.
        var last = DateOnly.FromDateTime(DateTime.UtcNow).AddDays(1);
        if (request.StartDate < first || request.StartDate > last) errors["startDate"] = ["Ngày bắt đầu phải từ năm 2000 và không ở tương lai."];
        if (request.EndDate is { } end && (end < request.StartDate || end > last)) errors["endDate"] = ["Ngày kết thúc phải từ ngày bắt đầu và không ở tương lai."];
        if (request.FlowLevel is not ("unspecified" or "light" or "medium" or "heavy")) errors["flowLevel"] = ["Mức độ dòng chảy không hợp lệ."];
        if (request.PainLevel is < 0 or > 10) errors["painLevel"] = ["Mức độ đau cần từ 0 đến 10."];
        if (request.Notes?.Length > 2000) errors["notes"] = ["Ghi chú tối đa 2000 ký tự."];
        return errors;
    }

    private static async Task<CycleSnapshot> Snapshot(CoupleDbContext db, Guid ownerId, bool partnerView)
    {
        var profile = await db.CycleProfiles.AsNoTracking().SingleOrDefaultAsync(item => item.UserId == ownerId);
        if (profile is null) return new(false, "private", 28, 5, [], null);
        var entries = await db.PeriodEntries.AsNoTracking().Where(item => item.UserId == ownerId)
            .OrderByDescending(item => item.StartDate).ToListAsync();
        var periods = entries.Select(item => new PeriodResponse(item.Id, item.StartDate, item.EndDate,
            item.FlowLevel, item.PainLevel, partnerView ? null : item.Notes, item.CreatedAt, item.UpdatedAt, item.Version)).ToArray();
        var prediction = profile.TrackingEnabled
            ? CycleEstimator.Estimate(entries.Select(item => item.StartDate), profile.AverageCycleLength) : null;
        return new(profile.TrackingEnabled, profile.Visibility == CycleVisibility.Partner ? "partner" : "private",
            profile.AverageCycleLength, profile.AveragePeriodLength, periods, prediction);
    }

    private static async Task RecordPrediction(CoupleDbContext db, CycleProfile profile)
    {
        var starts = await db.PeriodEntries.AsNoTracking().Where(item => item.UserId == profile.UserId)
            .OrderBy(item => item.StartDate).Select(item => item.StartDate).ToListAsync();
        var history = await db.CyclePredictions.Where(item => item.UserId == profile.UserId).ToListAsync();
        // Recalculate actual dates when records are corrected/deleted, without
        // treating retrospective entries as predictions made ahead of time.
        foreach (var item in history)
        {
            var next = starts.Where(start => start > item.AnchorStart).Select(start => (DateOnly?)start).FirstOrDefault();
            item.ActualStart = next >= DateOnly.FromDateTime(item.GeneratedAt.UtcDateTime) ? next : null;
            item.ErrorDays = item.ActualStart?.DayNumber - item.ExpectedStart.DayNumber;
        }
        var estimate = profile.TrackingEnabled ? CycleEstimator.Estimate(starts, profile.AverageCycleLength) : null;
        if (estimate is not null)
        {
            var anchor = starts[^1];
            var last = history.OrderByDescending(item => item.GeneratedAt).FirstOrDefault();
            if (last is null || last.AnchorStart != anchor || last.ExpectedStart != estimate.ExpectedStart ||
                last.EarliestStart != estimate.EarliestStart || last.LatestStart != estimate.LatestStart ||
                last.Basis != estimate.Basis || last.IntervalCount != estimate.IntervalCount)
                db.CyclePredictions.Add(new CyclePredictionRecord
                {
                    Id = Guid.NewGuid(), UserId = profile.UserId, AnchorStart = anchor,
                    ExpectedStart = estimate.ExpectedStart, EarliestStart = estimate.EarliestStart,
                    LatestStart = estimate.LatestStart, Basis = estimate.Basis, IntervalCount = estimate.IntervalCount,
                    AlgorithmVersion = CycleEstimator.Version, GeneratedAt = DateTimeOffset.UtcNow,
                });
        }
        await db.SaveChangesAsync();
    }

    private static async Task<AppUser?> CurrentUser(ClaimsPrincipal principal, CoupleDbContext db) =>
        Guid.TryParse(principal.FindFirst(JwtRegisteredClaimNames.Sub)?.Value, out var id)
            ? await db.Users.AsNoTracking().SingleOrDefaultAsync(user => user.Id == id) : null;
    private static IResult Hidden() => Results.NotFound(new { message = "Chưa có dữ liệu chu kỳ được chia sẻ với bạn." });
}
