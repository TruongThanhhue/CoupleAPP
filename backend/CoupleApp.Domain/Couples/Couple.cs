namespace CoupleApp.Domain.Couples;

/// <summary>
/// The shared workspace for two active members.
/// </summary>
public sealed class Couple
{
    private readonly List<CoupleMember> _members = [];

    public Couple(Guid id, string displayName, DateOnly relationshipStartedOn)
    {
        if (string.IsNullOrWhiteSpace(displayName))
        {
            throw new ArgumentException("A couple needs a display name.", nameof(displayName));
        }

        Id = id;
        DisplayName = displayName.Trim();
        RelationshipStartedOn = relationshipStartedOn;
    }

    public Guid Id { get; }
    public string DisplayName { get; }
    public DateOnly RelationshipStartedOn { get; }
    public IReadOnlyCollection<CoupleMember> Members => _members.AsReadOnly();

    public void AddMember(Guid userId, DateTimeOffset joinedAt)
    {
        if (_members.Any(member => member.UserId == userId && member.IsActive))
        {
            throw new InvalidOperationException("The user is already an active couple member.");
        }

        if (_members.Count(member => member.IsActive) >= 2)
        {
            throw new InvalidOperationException("A couple can have at most two active members.");
        }

        _members.Add(new CoupleMember(userId, joinedAt));
    }
}

public sealed record CoupleMember(Guid UserId, DateTimeOffset JoinedAt)
{
    public bool IsActive { get; private set; } = true;

    public void Leave() => IsActive = false;
}
