using Microsoft.EntityFrameworkCore;

namespace CoupleApp.API.Data;

public sealed class CoupleDbContext(DbContextOptions<CoupleDbContext> options) : DbContext(options)
{
    public DbSet<AppUser> Users => Set<AppUser>();
    public DbSet<PartnerInvite> PartnerInvites => Set<PartnerInvite>();
    public DbSet<WorkspaceTask> Tasks => Set<WorkspaceTask>();
    public DbSet<CalendarEvent> Events => Set<CalendarEvent>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
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
