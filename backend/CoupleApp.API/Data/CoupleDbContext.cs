using Microsoft.EntityFrameworkCore;

namespace CoupleApp.API.Data;

public sealed class CoupleDbContext(DbContextOptions<CoupleDbContext> options) : DbContext(options)
{
    public DbSet<AppUser> Users => Set<AppUser>();
    public DbSet<SharedEntry> SharedEntries => Set<SharedEntry>();
    public DbSet<PartnerInvite> PartnerInvites => Set<PartnerInvite>();
    public DbSet<WorkspaceTask> Tasks => Set<WorkspaceTask>();
    public DbSet<CalendarEvent> Events => Set<CalendarEvent>();
    public DbSet<CycleProfile> CycleProfiles => Set<CycleProfile>();
    public DbSet<PeriodEntry> PeriodEntries => Set<PeriodEntry>();
    public DbSet<CyclePredictionRecord> CyclePredictions => Set<CyclePredictionRecord>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        builder.Entity<SharedEntry>(entity =>
        {
            entity.HasOne<AppUser>().WithMany().HasForeignKey(e => e.OwnerId).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne<AppUser>().WithMany().HasForeignKey(e => e.RecipientId).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne<AppUser>().WithMany().HasForeignKey(e => e.PayerId).OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(e => new {e.OwnerId, e.RecipientId, e.Kind, e.Day}).HasDatabaseName("shared_entries_pair_month");
        });
        builder.Entity<CycleProfile>(entity =>
        {
            entity.ToTable("cycle_profiles");
            entity.HasKey(item => item.UserId);
            entity.HasOne<AppUser>().WithMany().HasForeignKey(item => item.UserId).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne<AppUser>().WithMany().HasForeignKey(item => item.SharedWithUserId).OnDelete(DeleteBehavior.Restrict);
        });
        builder.Entity<PeriodEntry>(entity =>
        {
            entity.ToTable("period_entries");
            entity.HasKey(item => item.Id);
            entity.Property(item => item.Version).IsConcurrencyToken();
            entity.Property(item => item.FlowLevel).HasMaxLength(16).IsRequired();
            entity.Property(item => item.Notes).HasMaxLength(2000);
            entity.HasIndex(item => new { item.UserId, item.StartDate }).IsUnique();
            entity.HasOne<CycleProfile>().WithMany().HasForeignKey(item => item.UserId).OnDelete(DeleteBehavior.Restrict);
        });
        builder.Entity<CyclePredictionRecord>(entity =>
        {
            entity.ToTable("cycle_predictions");
            entity.HasKey(item => item.Id);
            entity.Property(item => item.Basis).HasMaxLength(16).IsRequired();
            entity.Property(item => item.AlgorithmVersion).HasMaxLength(40).IsRequired();
            entity.HasIndex(item => new { item.UserId, item.GeneratedAt });
            entity.HasOne<CycleProfile>().WithMany().HasForeignKey(item => item.UserId).OnDelete(DeleteBehavior.Restrict);
        });
        builder.Entity<AppUser>(entity =>
        {
            entity.ToTable("users");
            entity.HasKey(user => user.Id);
            entity.Property(user => user.Email).HasMaxLength(320).IsRequired();
            entity.Property(user => user.NormalizedEmail).HasMaxLength(320).IsRequired();
            entity.Property(user => user.DisplayName).HasMaxLength(80).IsRequired();
            entity.Property(user => user.PartnerCode).HasMaxLength(16).IsRequired();
            entity.Property(user => user.PasswordHash).IsRequired();
            entity.Property(user => user.PasswordSalt).IsRequired();
            entity.Property(user => user.PartnerId).IsConcurrencyToken();
            entity.HasIndex(user => user.NormalizedEmail).IsUnique();
            entity.HasIndex(user => user.PartnerCode).IsUnique();
            entity.HasIndex(user => user.PartnerId).IsUnique();
            entity.HasOne<AppUser>().WithMany().HasForeignKey(user => user.PartnerId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        builder.Entity<PartnerInvite>(entity =>
        {
            entity.ToTable("partner_invites");
            entity.HasKey(invite => invite.Id);
            entity.Property(invite => invite.Status).IsConcurrencyToken();
            entity.HasIndex(invite => new { invite.SenderId, invite.RecipientId, invite.Status });
            entity.HasOne<AppUser>().WithMany().HasForeignKey(invite => invite.SenderId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne<AppUser>().WithMany().HasForeignKey(invite => invite.RecipientId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        builder.Entity<WorkspaceTask>(entity =>
        {
            entity.ToTable("workspace_tasks");
            entity.HasKey(item => item.Id);
            entity.Property(item => item.Title).HasMaxLength(200).IsRequired();
            entity.Property(item => item.Notes).HasMaxLength(2000);
            entity.Property(item => item.Priority).HasMaxLength(10).IsRequired();
            entity.Property(item => item.UpdatedAt).IsConcurrencyToken();
            entity.Property(item => item.Version).IsConcurrencyToken();
            entity.HasIndex(item => item.AssignedToUserId);
            entity.HasOne<AppUser>().WithMany().HasForeignKey(item => item.AssignedToUserId).OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(item => item.OwnerId);
            entity.HasIndex(item => item.SharedWithUserId);
            entity.HasOne<AppUser>().WithMany().HasForeignKey(item => item.OwnerId).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne<AppUser>().WithMany().HasForeignKey(item => item.SharedWithUserId).OnDelete(DeleteBehavior.Restrict);
        });

        builder.Entity<CalendarEvent>(entity =>
        {
            entity.ToTable("calendar_events");
            entity.HasKey(item => item.Id);
            entity.Property(item => item.Title).HasMaxLength(200).IsRequired();
            entity.Property(item => item.Notes).HasMaxLength(2000);
            entity.Property(item => item.Location).HasMaxLength(300);
            entity.Property(item => item.UpdatedAt).IsConcurrencyToken();
            entity.Property(item => item.Version).IsConcurrencyToken();
            entity.HasIndex(item => item.OwnerId);
            entity.HasIndex(item => item.SharedWithUserId);
            entity.HasOne<AppUser>().WithMany().HasForeignKey(item => item.OwnerId).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne<AppUser>().WithMany().HasForeignKey(item => item.SharedWithUserId).OnDelete(DeleteBehavior.Restrict);
        });
    }
}

public sealed class AppUser
{
    public Guid Id { get; set; }
    public required string Email { get; set; }
    public required string NormalizedEmail { get; set; }
    public required string DisplayName { get; set; }
    public required string PartnerCode { get; set; }
    public required byte[] PasswordHash { get; set; }
    public required byte[] PasswordSalt { get; set; }
    public Guid? PartnerId { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}

public sealed class PartnerInvite
{
    public Guid Id { get; set; }
    public Guid SenderId { get; set; }
    public Guid RecipientId { get; set; }
    public InviteStatus Status { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset? RespondedAt { get; set; }
}

public enum InviteStatus { Pending, Accepted, Declined, Cancelled }
