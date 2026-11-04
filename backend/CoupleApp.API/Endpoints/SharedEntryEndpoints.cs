using System.Globalization;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using CoupleApp.API.Data;
using Microsoft.EntityFrameworkCore;

namespace CoupleApp.API.Endpoints;

public static class SharedEntryEndpoints
{
    public sealed record EntryInput(string? Title, DateOnly Day, string? Detail, long? Amount, string? PaidBy, Guid? RequestId = null);
    public sealed record ShoppingState(bool Done);

    public static void MapSharedEntries(this WebApplication app)
    {
        var group = app.MapGroup("/api/v1/shared/{kind}").RequireAuthorization();
        group.AddEndpointFilter(async (context, next) =>
        {
            var http = context.HttpContext;
            if (http.Request.RouteValues["kind"]?.ToString() is not ("expenses" or "shopping" or "memories" or "anniversaries")) return Results.NotFound();
            if (!Guid.TryParse(http.User.FindFirstValue(JwtRegisteredClaimNames.Sub), out var user)) return Results.Unauthorized();
            var db = http.RequestServices.GetRequiredService<CoupleDbContext>();
            await using var tx = await AccountWriteLock.BeginAsync(db, user);
            var code = http.Request.Query["partnerCode"].ToString();
            var partner = await (from a in db.Users from b in db.Users
                                 where a.Id == user && a.PartnerId == b.Id && b.PartnerId == user && b.PartnerCode == code
                                 select (Guid?)b.Id).SingleOrDefaultAsync();
            if (partner is null) return Results.Conflict(new { message = "Kết nối đã thay đổi. Hãy mở lại màn hình." });
            http.Items["pair"] = (user, partner.Value);
            var result = await next(context);
            await tx.CommitAsync();
            return result;
        });
        group.MapGet("", async (HttpContext http, CoupleDbContext db, string kind, string? month) =>
        {
            var (user, partner) = Pair(http);
            var items = Visible(db, kind, user, partner);
            if (kind == "expenses")
            {
                if (!DateOnly.TryParseExact(month + "-01", "yyyy-MM-dd", CultureInfo.InvariantCulture,
                    DateTimeStyles.None, out var start) || start.Year is < 1900 or > 2100) return Results.BadRequest();
                var end = start.AddMonths(1);
                items = items.Where(e => e.Day >= start && e.Day < end);
            }
            var rows = await items.OrderByDescending(e => e.Day).ThenBy(e => e.Id).Select(e => new {
                e.Id, e.Title, e.Detail, e.Day, e.Amount, e.Done, paidByMe = e.PayerId == user, createdByMe = e.OwnerId == user
            }).ToListAsync();
            return Results.Ok(new { items = rows, total = rows.Sum(e => (decimal)(e.Amount ?? 0)) });
        });
        group.MapPost("", async (HttpContext http, CoupleDbContext db, string kind, EntryInput body) =>
        {
            var (user, partner) = Pair(http);
            var title = body.Title?.Trim();
            if (string.IsNullOrEmpty(title) || title.Length > 160 || body.Detail?.Length > 2000 || body.Day.Year is < 1900 or > 2100)
                return Results.BadRequest(new {message = "Kiểm tra tên, ngày và ghi chú."});
            if (kind == "expenses" && (body.Amount is null or <= 0 or > 999999999999 || body.PaidBy is not ("me" or "partner")))
                return Results.BadRequest(new {message = "Nhập số tiền VND dương và chọn người trả."});
            var entry = new SharedEntry { Id = body.RequestId ?? Guid.NewGuid(), Kind = kind, Title = title, Day = body.Day,
                Detail = body.Detail?.Trim(), OwnerId = user, RecipientId = partner,
                Amount = kind == "expenses" ? body.Amount : null,
                PayerId = kind == "expenses" ? (body.PaidBy == "me" ? user : partner) : null };
            if (body.RequestId.HasValue && await db.SharedEntries.FindAsync(entry.Id) is { } saved)
            {
                if (saved.OwnerId == user && saved.RecipientId == partner && saved.Kind == kind &&
                    saved.Title == entry.Title && saved.Amount == entry.Amount && saved.PayerId == entry.PayerId &&
                    saved.Detail == entry.Detail && saved.Day == entry.Day) return Results.Ok(new { saved.Id });
                return Results.Conflict(new { message = "Yêu cầu này đã được lưu. Hãy tải lại danh sách." });
            }
            db.SharedEntries.Add(entry);
            await db.SaveChangesAsync();
            return Results.Created($"/api/v1/shared/{kind}/{entry.Id}", new { entry.Id });
        });
        group.MapPut("/{id:guid}", async (HttpContext http, CoupleDbContext db, string kind, Guid id, ShoppingState state) =>
        {
            if (kind != "shopping") return Results.NotFound();
            var (user, partner) = Pair(http);
            var count = await Visible(db, kind, user, partner).Where(e => e.Id == id)
                .ExecuteUpdateAsync(set => set.SetProperty(e => e.Done, state.Done));
            return count == 1 ? Results.NoContent() : Results.NotFound();
        });
        group.MapDelete("/{id:guid}", async (HttpContext http, CoupleDbContext db, string kind, Guid id) =>
        {
            var (user, partner) = Pair(http);
            var count = await Visible(db, kind, user, partner).Where(e => e.Id == id && e.OwnerId == user).ExecuteDeleteAsync();
            return count == 1 ? Results.NoContent() : Results.NotFound();
        });
    }

    private static (Guid, Guid) Pair(HttpContext http) => ((Guid, Guid))http.Items["pair"]!;
    private static IQueryable<SharedEntry> Visible(CoupleDbContext db, string kind, Guid user, Guid partner) =>
        db.SharedEntries.Where(e => e.Kind == kind && ((e.OwnerId == user && e.RecipientId == partner) ||
            (e.OwnerId == partner && e.RecipientId == user)));
}
