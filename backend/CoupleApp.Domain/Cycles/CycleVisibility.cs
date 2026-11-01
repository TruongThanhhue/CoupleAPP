namespace CoupleApp.Domain.Cycles;

/// <summary>
/// Declares whether the account owner permits their active partner to view cycle data.
/// Authorization remains a server-side responsibility.
/// </summary>
public enum CycleVisibility
{
    Private = 0,
    Partner = 1,
}
