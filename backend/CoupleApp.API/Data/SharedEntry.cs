using System.ComponentModel.DataAnnotations.Schema;

namespace CoupleApp.API.Data;

[Table("shared_entries")]
public sealed class SharedEntry
{
    public Guid Id { get; set; }
    public Guid OwnerId { get; set; }
    public Guid? RecipientId { get; set; }
    public required string Kind { get; set; }
    public required string Title { get; set; }
    public DateOnly Day { get; set; }
    public string? Detail { get; set; }
    public long? Amount { get; set; }
    public Guid? PayerId { get; set; }
    public bool Done { get; set; }
}
