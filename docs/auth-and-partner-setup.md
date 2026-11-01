# Run authentication and partner connection locally

The current implementation uses Flutter, ASP.NET Core 9, and PostgreSQL. Account, partner connection, tasks and calendar events use the API. Location and the other roadmap modules are still prototypes.

## API

Create an empty PostgreSQL database named `couple_app`. In `backend/CoupleApp.API`, configure local secrets:

```powershell
dotnet user-secrets init
dotnet user-secrets set "Jwt:Key" "replace-with-a-random-secret-of-at-least-32-bytes"
dotnet user-secrets set "ConnectionStrings:CoupleDb" "Host=localhost;Port=5432;Database=couple_app;Username=postgres;Password=YOUR_LOCAL_PASSWORD"
dotnet run --launch-profile http
```

`dotnet user-secrets` stores secrets outside the repository. The development API listens on `http://localhost:5248` and creates the initial schema on startup. Do not use `EnsureCreated` as a production migration strategy.

## Flutter

From `mobile/couple_app`:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5248/api/v1
```

`10.0.2.2` is the host computer from an Android emulator. For an actual phone, supply an HTTPS API URL reachable from the device. Android cleartext HTTP is enabled only for debug builds.

Register two accounts on separate devices or emulators. Share one account's `CPL-XXXXXXXX` code, enter it in **Thêm → Kết nối partner**, and confirm the incoming invitation on the second account. The sender can cancel a pending invitation. The partner link becomes active only after acceptance.

## Tasks and calendar

In **Việc cần làm**, create a task, set priority and an optional due date, then
mark it complete or edit/delete it. In **Lịch**, create an event with start/end
times and an optional location. The default visibility is **Chỉ mình bạn**;
sharing requires a connected partner. A partner can edit shared content, while
only its creator can change its visibility. Deletion asks for confirmation.

The home screen shows actual task progress and today's events. Pull down to
refresh after another person changes data; switching tabs or returning to the
app also refreshes it. Realtime delivery and reminder notifications are not yet
implemented.
