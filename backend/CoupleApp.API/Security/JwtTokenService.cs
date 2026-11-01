using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using CoupleApp.API.Data;
using Microsoft.IdentityModel.Tokens;

namespace CoupleApp.API.Security;

public sealed class JwtTokenService(IConfiguration configuration)
{
    public string Create(AppUser user)
    {
        var jwt = configuration.GetRequiredSection("Jwt");
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt["Key"]!));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, user.Email),
            new Claim("name", user.DisplayName),
        };

        return new JwtSecurityTokenHandler().WriteToken(new JwtSecurityToken(
            issuer: jwt["Issuer"], audience: jwt["Audience"], claims: claims,
            notBefore: DateTime.UtcNow, expires: DateTime.UtcNow.AddDays(14), signingCredentials: credentials));
    }
}
