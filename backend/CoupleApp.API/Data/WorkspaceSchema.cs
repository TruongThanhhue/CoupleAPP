using Microsoft.EntityFrameworkCore;

namespace CoupleApp.API.Data;

public static class WorkspaceSchema
{
    /// <summary>Additive upgrade for databases initially created by EnsureCreated.</summary>
    public static async Task EnsureWorkspaceSchemaAsync(this CoupleDbContext db)
    {
        await using var transaction = await db.Database.BeginTransactionAsync();
        await db.Database.ExecuteSqlRawAsync("SELECT pg_advisory_xact_lock(61409031)");
        foreach (var name in new[] { "001_workspace.sql", "002_cycles.sql", "003_workspace_assignment_versions.sql",
            "004_cycle_period_versions.sql" })
        {
            using var stream = typeof(WorkspaceSchema).Assembly.GetManifestResourceStream(
                $"CoupleApp.API.Data.Migrations.{name}")
                ?? throw new InvalidOperationException($"Schema resource {name} is missing.");
            using var reader = new StreamReader(stream);
            await db.Database.ExecuteSqlRawAsync(await reader.ReadToEndAsync());
        }
        await transaction.CommitAsync();
    }
}
