using System.IdentityModel.Tokens.Jwt;
using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;

namespace CoupleApp.API.Data;

/// <summary>Serializes membership changes with writes authorized by that membership.</summary>
public static class AccountWriteLock
{
    public static async Task<IDbContextTransaction> BeginAsync(CoupleDbContext db, params Guid[] accountIds)
    {
        var transaction = await db.Database.BeginTransactionAsync();
        try
        {
            // Stable ordering prevents deadlocks; a hash collision only serializes unrelated users.
            var keys = accountIds.Select(id => BitConverter.ToInt64(SHA256.HashData(id.ToByteArray()), 0))
                .Distinct().Order().ToArray();
            foreach (var key in keys)
                await db.Database.ExecuteSqlInterpolatedAsync($"SELECT pg_advisory_xact_lock({key})");
            return transaction;
        }
        catch
        {
            await transaction.DisposeAsync();
            throw;
        }
    }

    public static async ValueTask<object?> Filter(EndpointFilterInvocationContext context, EndpointFilterDelegate next)
    {
        if (HttpMethods.IsGet(context.HttpContext.Request.Method)) return await next(context);
        if (!Guid.TryParse(context.HttpContext.User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value, out var id))
            return Results.Unauthorized();
        var db = context.HttpContext.RequestServices.GetRequiredService<CoupleDbContext>();
        await using var transaction = await BeginAsync(db, id);
        var result = await next(context);
        if (result is IStatusCodeHttpResult status && status.StatusCode is >= 400) return result;
        await transaction.CommitAsync();
        return result;
    }
}
