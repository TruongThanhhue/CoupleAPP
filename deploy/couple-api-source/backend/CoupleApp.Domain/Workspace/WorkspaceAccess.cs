namespace CoupleApp.Domain.Workspace;

/// <summary>Visibility is bound to the partner chosen when sharing, never to a future partner.</summary>
public static class WorkspaceAccess
{
    public static bool CanRead(Guid viewerId, Guid ownerId, Guid? sharedWithId, Guid? mutualPartnerId) =>
        viewerId == ownerId || (sharedWithId == viewerId && mutualPartnerId == ownerId);

    public static bool CanChangeSharing(Guid viewerId, Guid ownerId, Guid? sharedWithId, bool requestedShared) =>
        viewerId == ownerId || requestedShared == sharedWithId.HasValue;
}
