using Microsoft.EntityFrameworkCore;

namespace CoupleApp.API.Data;

public static class WorkspaceSchema
{
    /// <summary>Additive upgrade for databases initially created by EnsureCreated.</summary>
    public static async Task EnsureWorkspaceSchemaAsync(this CoupleDbContext db)
    {
        using var stream = typeof(WorkspaceSchema).Assembly.GetManifestResourceStream(
            "CoupleApp.API.Data.Migrations.001_workspace.sql")
            ?? throw new InvalidOperationException("Workspace schema resource is missing.");
        using var reader = new StreamReader(stream);
        var sql = await reader.ReadToEndAsync();
        await using var transaction = await db.Database.BeginTransactionAsync();
        await db.Database.ExecuteSqlRawAsync("SELECT pg_advisory_xact_lock(61409031)");
        await db.Database.ExecuteSqlRawAsync(sql);
        await transaction.CommitAsync();
    }
}
