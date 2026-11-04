FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY . .
RUN dotnet publish CoupleApp.API/CoupleApp.API.csproj -c Release -o /out --no-self-contained

FROM mcr.microsoft.com/dotnet/aspnet:9.0
WORKDIR /app
COPY --from=build /out .
ENV ASPNETCORE_HTTP_PORTS=8080
USER app
ENTRYPOINT ["dotnet", "CoupleApp.API.dll"]
