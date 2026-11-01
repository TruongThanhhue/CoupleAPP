using CoupleApp.Domain.Workspace;

namespace CoupleApp.Domain.Tests.Workspace;

public sealed class WorkspaceAccessTests
{
    private readonly Guid _owner = Guid.NewGuid();
    private readonly Guid _partner = Guid.NewGuid();
    private readonly Guid _stranger = Guid.NewGuid();

    [Fact]
    public void OwnerCanReadPrivateRecordWithoutPartner() =>
        Assert.True(WorkspaceAccess.CanRead(_owner, _owner, null, null));

    [Fact]
    public void CurrentPartnerCannotReadPrivateRecord() =>
        Assert.False(WorkspaceAccess.CanRead(_partner, _owner, null, _owner));

    [Fact]
    public void CapturedCurrentPartnerCanReadSharedRecord() =>
        Assert.True(WorkspaceAccess.CanRead(_partner, _owner, _partner, _owner));

    [Fact]
    public void FormerPartnerCannotReadSharedRecord() =>
        Assert.False(WorkspaceAccess.CanRead(_partner, _owner, _partner, null));

    [Fact]
    public void NewPartnerDoesNotInheritPreviouslySharedRecord() =>
        Assert.False(WorkspaceAccess.CanRead(_stranger, _owner, _partner, _owner));

    [Fact]
    public void UnrelatedUserCannotReadSharedRecord() =>
        Assert.False(WorkspaceAccess.CanRead(_stranger, _owner, _partner, null));

    [Fact]
    public void PartnerCannotHideOwnersSharedRecord() =>
        Assert.False(WorkspaceAccess.CanChangeSharing(_partner, _owner, _partner, false));

    [Fact]
    public void PartnerCanRetainSharingWhileEditingContent() =>
        Assert.True(WorkspaceAccess.CanChangeSharing(_partner, _owner, _partner, true));

    [Fact]
    public void OwnerCanMakeSharedRecordPrivate() =>
        Assert.True(WorkspaceAccess.CanChangeSharing(_owner, _owner, _partner, false));
}
