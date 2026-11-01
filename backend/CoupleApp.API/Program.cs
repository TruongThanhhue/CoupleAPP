using System.IdentityModel.Tokens.Jwt;
using System.Net.Mail;
using System.Security.Cryptography;
using System.Security.Claims;
using System.Text;
using System.Threading.RateLimiting;
using CoupleApp.API.Contracts;
using CoupleApp.API.Data;
using CoupleApp.API.Endpoints;
using CoupleApp.API.Security;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Npgsql;

var builder = WebApplication.CreateBuilder(args);
var jwt = builder.Configuration.GetRequiredSection("Jwt");
var jwtKey = jwt["Key"];

if (string.IsNullOrWhiteSpace(jwtKey) || Encoding.UTF8.GetByteCount(jwtKey) < 32)
{
    throw new InvalidOperationException("Set Jwt:Key to a random secret of at least 32 bytes through user secrets or an environment variable.");
}

var connectionString = builder.Configuration.GetConnectionString("CoupleDb")
    ?? throw new InvalidOperationException("Set the CoupleDb connection string before starting the API.");

builder.Services.AddProblemDetails();
builder.Services.AddDbContext<CoupleDbContext>(options => options.UseNpgsql(connectionString));
builder.Services.AddScoped<JwtTokenService>();
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.MapInboundClaims = false;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwt["Issuer"],
            ValidateAudience = true,
            ValidAudience = jwt["Audience"],
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            ClockSkew = TimeSpan.FromMinutes(1),
        };
    });
builder.Services.AddAuthorization();
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddPolicy("auth", context => RateLimitPartition.GetFixedWindowLimiter(
        context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
        _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = 8,
            Window = TimeSpan.FromMinutes(1),
            QueueLimit = 0,
            AutoReplenishment = true,
        }));
    options.AddPolicy("partner-invite", context => RateLimitPartition.GetFixedWindowLimiter(
        context.User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value ?? "unknown",
        _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = 10,
            Window = TimeSpan.FromHours(1),
            QueueLimit = 0,
            AutoReplenishment = true,
        }));
});

var app = builder.Build();
if (app.Environment.IsDevelopment())
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<CoupleDbContext>();
    await db.Database.EnsureCreatedAsync();
    await db.EnsureWorkspaceSchemaAsync();
}
app.UseExceptionHandler();
app.UseAuthentication();
app.UseRateLimiter();
app.UseAuthorization();

app.MapGet("/health", () => Results.Ok(new { status = "healthy" })).WithTags("System");
app.MapWorkspaceEndpoints();

var auth = app.MapGroup("/api/v1/auth").WithTags("Authentication").RequireRateLimiting("auth");
auth.MapPost("/register", async (RegisterRequest request, CoupleDbContext db, JwtTokenService tokens) =>
{
    var errors = ValidateRegistration(request);
    if (errors.Count > 0) return Results.ValidationProblem(errors);

    var normalizedEmail = request.Email.Trim().ToUpperInvariant();
    if (await db.Users.AnyAsync(user => user.NormalizedEmail == normalizedEmail)) return Results.Conflict(new { message = "Email này đã được sử dụng." });

    var (hash, salt) = PasswordHasher.Hash(request.Password);
    var user = new AppUser
    {
        Id = Guid.NewGuid(), Email = request.Email.Trim(), NormalizedEmail = normalizedEmail,
        DisplayName = request.DisplayName.Trim(), PartnerCode = await GeneratePartnerCodeAsync(db),
        PasswordHash = hash, PasswordSalt = salt, CreatedAt = DateTimeOffset.UtcNow,
    };
    db.Users.Add(user);
    try
    {
        await db.SaveChangesAsync();
    }
    catch (DbUpdateException error) when (error.InnerException is PostgresException { SqlState: "23505" })
    {
        return Results.Conflict(new { message = "Email hoặc mã cá nhân đã được sử dụng. Vui lòng thử lại." });
    }
    return Results.Created("/api/v1/couples/me", new AuthResponse(tokens.Create(user), ToProfile(user, null)));
});

auth.MapPost("/login", async (LoginRequest request, CoupleDbContext db, JwtTokenService tokens) =>
{
    if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrEmpty(request.Password)) return Results.Unauthorized();
    var user = await db.Users.SingleOrDefaultAsync(candidate => candidate.NormalizedEmail == request.Email.Trim().ToUpperInvariant());
    if (user is null || !PasswordHasher.Verify(request.Password, user.PasswordHash, user.PasswordSalt)) return Results.Unauthorized();
    var partner = user.PartnerId is null ? null : await db.Users.FindAsync(user.PartnerId);
    return Results.Ok(new AuthResponse(tokens.Create(user), ToProfile(user, partner)));
});

var couples = app.MapGroup("/api/v1/couples").WithTags("Couples").RequireAuthorization();
couples.MapGet("/me", async (ClaimsPrincipal principal, CoupleDbContext db) =>
{
    var user = await GetCurrentUserAsync(principal, db);
    if (user is null) return Results.Unauthorized();
    var partner = user.PartnerId is null ? null : await db.Users.FindAsync(user.PartnerId);
    return Results.Ok(ToProfile(user, partner));
});

couples.MapPut("/me", async (UpdateProfileRequest request, ClaimsPrincipal principal, CoupleDbContext db) =>
{
    if (!Guid.TryParse(principal.FindFirst(JwtRegisteredClaimNames.Sub)?.Value, out var userId)) return Results.Unauthorized();
    await using var transaction = await AccountWriteLock.BeginAsync(db, userId);
    var user = await db.Users.FindAsync(userId);
    if (user is null) return Results.Unauthorized();
    if (string.IsNullOrWhiteSpace(request.DisplayName) || request.DisplayName.Trim().Length > 80)
        return Results.ValidationProblem(new Dictionary<string, string[]> { ["displayName"] = ["Tên hiển thị cần có từ 1 đến 80 ký tự."] });
    user.DisplayName = request.DisplayName.Trim();
    await db.SaveChangesAsync();
    var partner = user.PartnerId is null ? null : await db.Users.FindAsync(user.PartnerId);
    await transaction.CommitAsync();
    return Results.Ok(ToProfile(user, partner));
});

couples.MapPost("/disconnect", async (DisconnectPartnerRequest request, ClaimsPrincipal principal, CoupleDbContext db) =>
{
    if (string.IsNullOrWhiteSpace(request.PartnerCode))
        return Results.BadRequest(new { message = "Hãy xác nhận partner cần ngắt kết nối." });
    if (!Guid.TryParse(principal.FindFirst(JwtRegisteredClaimNames.Sub)?.Value, out var userId)) return Results.Unauthorized();
    var snapshot = await db.Users.AsNoTracking().SingleOrDefaultAsync(user => user.Id == userId);
    if (snapshot is null) return Results.Unauthorized();
    await using var transaction = await AccountWriteLock.BeginAsync(db, userId, snapshot.PartnerId ?? userId);
    var user = await db.Users.FindAsync(userId);
    if (user is null) return Results.Unauthorized();
    // Reload after locking: an earlier dialog may refer to an entirely different relationship.
    if (user.PartnerId != snapshot.PartnerId)
        return Results.Conflict(new { message = "Kết nối vừa thay đổi. Hãy tải lại trước khi ngắt kết nối." });
    if (user.PartnerId is null) return Results.Ok(ToProfile(user, null));
    var partner = await db.Users.FindAsync(user.PartnerId);
    if (partner is null || partner.PartnerId != user.Id ||
        partner.PartnerCode != request.PartnerCode.Trim().ToUpperInvariant())
        return Results.Conflict(new { message = "Partner không còn khớp với xác nhận. Hãy tải lại." });

    var partnerId = partner.Id;
    user.PartnerId = null;
    partner.PartnerId = null;
    var now = DateTimeOffset.UtcNow;
    await db.Tasks.Where(item => (item.OwnerId == userId && item.SharedWithUserId == partnerId) ||
        (item.OwnerId == partnerId && item.SharedWithUserId == userId))
        .ExecuteUpdateAsync(setters => setters.SetProperty(item => item.SharedWithUserId, (Guid?)null)
            .SetProperty(item => item.UpdatedAt, now));
    await db.Events.Where(item => (item.OwnerId == userId && item.SharedWithUserId == partnerId) ||
        (item.OwnerId == partnerId && item.SharedWithUserId == userId))
        .ExecuteUpdateAsync(setters => setters.SetProperty(item => item.SharedWithUserId, (Guid?)null)
            .SetProperty(item => item.UpdatedAt, now));
    await db.PartnerInvites.Where(invite => invite.Status == InviteStatus.Pending &&
        (invite.SenderId == userId || invite.RecipientId == userId || invite.SenderId == partnerId || invite.RecipientId == partnerId))
        .ExecuteUpdateAsync(setters => setters.SetProperty(invite => invite.Status, InviteStatus.Cancelled)
            .SetProperty(invite => invite.RespondedAt, (DateTimeOffset?)now));
    await db.SaveChangesAsync();
    await transaction.CommitAsync();
    return Results.Ok(ToProfile(user, null));
});

couples.MapGet("/invites", async (ClaimsPrincipal principal, CoupleDbContext db) =>
{
    var user = await GetCurrentUserAsync(principal, db);
    if (user is null) return Results.Unauthorized();
    if (user.PartnerId is not null) return Results.Ok(Array.Empty<PartnerInviteResponse>());
    var invites = await db.PartnerInvites.Where(invite => invite.RecipientId == user.Id && invite.Status == InviteStatus.Pending)
        .OrderByDescending(invite => invite.CreatedAt)
        .Join(db.Users, invite => invite.SenderId, sender => sender.Id,
            (invite, sender) => new PartnerInviteResponse(invite.Id, sender.DisplayName, invite.Status.ToString(), invite.CreatedAt)).ToListAsync();
    return Results.Ok(invites);
});

couples.MapGet("/invites/sent", async (ClaimsPrincipal principal, CoupleDbContext db) =>
{
    var user = await GetCurrentUserAsync(principal, db);
    if (user is null) return Results.Unauthorized();
    if (user.PartnerId is not null) return Results.Ok(Array.Empty<SentPartnerInviteResponse>());
    var invites = await db.PartnerInvites
        .Where(invite => invite.SenderId == user.Id && invite.Status == InviteStatus.Pending)
        .OrderByDescending(invite => invite.CreatedAt)
        .Join(db.Users, invite => invite.RecipientId, recipient => recipient.Id,
            (invite, recipient) => new SentPartnerInviteResponse(invite.Id, recipient.DisplayName, invite.CreatedAt))
        .ToListAsync();
    return Results.Ok(invites);
});

couples.MapPost("/invites", async (SendPartnerInviteRequest request, ClaimsPrincipal principal, CoupleDbContext db) =>
{
    if (!Guid.TryParse(principal.FindFirst(JwtRegisteredClaimNames.Sub)?.Value, out var senderId)) return Results.Unauthorized();
    if (string.IsNullOrWhiteSpace(request.PartnerCode)) return Results.BadRequest(new { message = "Hãy nhập mã partner." });
    var recipientId = await db.Users.AsNoTracking().Where(user => user.PartnerCode == request.PartnerCode.Trim().ToUpperInvariant())
        .Select(user => (Guid?)user.Id).SingleOrDefaultAsync();
    if (recipientId is null || recipientId == senderId) return Results.BadRequest(new { message = "Mã partner không hợp lệ." });
    await using var transaction = await AccountWriteLock.BeginAsync(db, senderId, recipientId.Value);
    var sender = await db.Users.FindAsync(senderId);
    if (sender is null) return Results.Unauthorized();
    if (sender.PartnerId is not null) return Results.Conflict(new { message = "Bạn đã kết nối với một partner." });
    var recipient = await db.Users.FindAsync(recipientId.Value);
    if (recipient is null) return Results.BadRequest(new { message = "Mã partner không hợp lệ." });
    if (recipient.PartnerId is not null) return Results.Conflict(new { message = "Người này đã kết nối với partner khác." });
    if (await db.PartnerInvites.AnyAsync(invite =>
        invite.Status == InviteStatus.Pending &&
        ((invite.SenderId == sender.Id && invite.RecipientId == recipient.Id) ||
         (invite.SenderId == recipient.Id && invite.RecipientId == sender.Id))))
        return Results.Conflict(new { message = "Hai bạn đã có một lời mời đang chờ phản hồi." });

    var invite = new PartnerInvite { Id = Guid.NewGuid(), SenderId = sender.Id, RecipientId = recipient.Id, Status = InviteStatus.Pending, CreatedAt = DateTimeOffset.UtcNow };
    db.PartnerInvites.Add(invite);
    await db.SaveChangesAsync();
    await transaction.CommitAsync();
    return Results.Created($"/api/v1/couples/invites/{invite.Id}", new { invite.Id, status = invite.Status.ToString() });
}).RequireRateLimiting("partner-invite");

couples.MapPost("/invites/{inviteId:guid}/accept", async (Guid inviteId, ClaimsPrincipal principal, CoupleDbContext db) =>
{
    if (!Guid.TryParse(principal.FindFirst(JwtRegisteredClaimNames.Sub)?.Value, out var recipientId)) return Results.Unauthorized();
    var pending = await db.PartnerInvites.AsNoTracking().SingleOrDefaultAsync(item => item.Id == inviteId && item.RecipientId == recipientId);
    if (pending is null) return Results.NotFound();
    await using var transaction = await AccountWriteLock.BeginAsync(db, recipientId, pending.SenderId);
    var recipient = await db.Users.FindAsync(recipientId);
    if (recipient is null) return Results.Unauthorized();
    var invite = await db.PartnerInvites.SingleOrDefaultAsync(item => item.Id == inviteId && item.RecipientId == recipient.Id && item.Status == InviteStatus.Pending);
    if (invite is null) return Results.NotFound();
    var sender = await db.Users.FindAsync(invite.SenderId);
    if (sender is null || sender.PartnerId is not null || recipient.PartnerId is not null) return Results.Conflict(new { message = "Lời mời không còn hợp lệ vì một trong hai người đã kết nối." });
    sender.PartnerId = recipient.Id;
    recipient.PartnerId = sender.Id;
    invite.Status = InviteStatus.Accepted;
    invite.RespondedAt = DateTimeOffset.UtcNow;
    var obsoleteInvites = await db.PartnerInvites.Where(item => item.Id != invite.Id &&
        item.Status == InviteStatus.Pending &&
        (item.SenderId == sender.Id || item.RecipientId == sender.Id ||
         item.SenderId == recipient.Id || item.RecipientId == recipient.Id)).ToListAsync();
    foreach (var obsolete in obsoleteInvites)
    {
        obsolete.Status = InviteStatus.Cancelled;
        obsolete.RespondedAt = invite.RespondedAt;
    }
    try
    {
        await db.SaveChangesAsync();
        await transaction.CommitAsync();
    }
    catch (DbUpdateException)
    {
        return Results.Conflict(new { message = "Lời mời vừa thay đổi. Vui lòng tải lại." });
    }
    catch (PostgresException error) when (error.SqlState is "40001" or "40P01")
    {
        return Results.Conflict(new { message = "Lời mời vừa thay đổi. Vui lòng tải lại." });
    }
    return Results.Ok(ToProfile(recipient, sender));
});

couples.MapPost("/invites/{inviteId:guid}/decline", async (Guid inviteId, ClaimsPrincipal principal, CoupleDbContext db) =>
{
    var recipient = await GetCurrentUserAsync(principal, db);
    if (recipient is null) return Results.Unauthorized();
    var invite = await db.PartnerInvites.SingleOrDefaultAsync(item => item.Id == inviteId && item.RecipientId == recipient.Id && item.Status == InviteStatus.Pending);
    if (invite is null) return Results.NotFound();
    invite.Status = InviteStatus.Declined;
    invite.RespondedAt = DateTimeOffset.UtcNow;
    try
    {
        await db.SaveChangesAsync();
    }
    catch (DbUpdateConcurrencyException)
    {
        return Results.Conflict(new { message = "Lời mời vừa thay đổi. Vui lòng tải lại." });
    }
    return Results.NoContent();
});

couples.MapPost("/invites/{inviteId:guid}/cancel", async (Guid inviteId, ClaimsPrincipal principal, CoupleDbContext db) =>
{
    var sender = await GetCurrentUserAsync(principal, db);
    if (sender is null) return Results.Unauthorized();
    var invite = await db.PartnerInvites.SingleOrDefaultAsync(item => item.Id == inviteId &&
        item.SenderId == sender.Id && item.Status == InviteStatus.Pending);
    if (invite is null) return Results.NotFound();
    invite.Status = InviteStatus.Cancelled;
    invite.RespondedAt = DateTimeOffset.UtcNow;
    try
    {
        await db.SaveChangesAsync();
    }
    catch (DbUpdateConcurrencyException)
    {
        return Results.Conflict(new { message = "Lời mời vừa thay đổi. Vui lòng tải lại." });
    }
    return Results.NoContent();
});

app.Run();

static Dictionary<string, string[]> ValidateRegistration(RegisterRequest request)
{
    var errors = new Dictionary<string, string[]>();
    if (string.IsNullOrWhiteSpace(request.Email) || request.Email.Length > 320 ||
        !MailAddress.TryCreate(request.Email.Trim(), out _))
        errors["email"] = ["Email không hợp lệ."];
    if (request.Password is null || request.Password.Length is < 12 or > 1024)
        errors["password"] = ["Mật khẩu cần từ 12 đến 1024 ký tự."];
    if (string.IsNullOrWhiteSpace(request.DisplayName) || request.DisplayName.Trim().Length > 80) errors["displayName"] = ["Tên hiển thị cần có từ 1 đến 80 ký tự."];
    return errors;
}

static async Task<string> GeneratePartnerCodeAsync(CoupleDbContext db)
{
    const string alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    for (var attempt = 0; attempt < 10; attempt++)
    {
    var code = $"CPL-{string.Concat(Enumerable.Range(0, 8).Select(_ => alphabet[RandomNumberGenerator.GetInt32(alphabet.Length)]))}";
        if (!await db.Users.AnyAsync(user => user.PartnerCode == code)) return code;
    }
    throw new InvalidOperationException("Could not allocate a unique partner code.");
}

static async Task<AppUser?> GetCurrentUserAsync(ClaimsPrincipal principal, CoupleDbContext db)
{
    var subject = principal.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
    return Guid.TryParse(subject, out var userId) ? await db.Users.FindAsync(userId) : null;
}

static UserProfile ToProfile(AppUser user, AppUser? partner) => new(user.DisplayName, user.PartnerCode, partner is null ? null : new PartnerProfile(partner.DisplayName, partner.PartnerCode));
