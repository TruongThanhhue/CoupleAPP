using CoupleApp.Domain.Couples;

namespace CoupleApp.Domain.Tests.Couples;

public sealed class CoupleTests
{
    [Fact]
    public void AddMember_Rejects_AThirdActiveMember()
    {
        var couple = new Couple(Guid.NewGuid(), "Minh & An", new DateOnly(2023, 5, 12));
        couple.AddMember(Guid.NewGuid(), DateTimeOffset.UtcNow);
        couple.AddMember(Guid.NewGuid(), DateTimeOffset.UtcNow);

        var action = () => couple.AddMember(Guid.NewGuid(), DateTimeOffset.UtcNow);

        Assert.Throws<InvalidOperationException>(action);
    }

    [Fact]
    public void AddMember_AllowsReplacementAfterAMemberLeaves()
    {
        var couple = new Couple(Guid.NewGuid(), "Minh & An", new DateOnly(2023, 5, 12));
        couple.AddMember(Guid.NewGuid(), DateTimeOffset.UtcNow);
        couple.AddMember(Guid.NewGuid(), DateTimeOffset.UtcNow);
        couple.Members.First().Leave();

        couple.AddMember(Guid.NewGuid(), DateTimeOffset.UtcNow);

        Assert.Equal(2, couple.Members.Count(member => member.IsActive));
    }
}
