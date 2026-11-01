# Couple App — Class Diagram

Sơ đồ dưới đây mô tả lớp tài khoản/kết nối trong backend và Flutter client. `AppUser` và `PartnerInvite` được lưu bằng Entity Framework Core; `Couple`/`CoupleMember` là domain model độc lập. Phần việc và lịch được bổ sung trong sơ đồ riêng phía dưới. `DemoDashboardQuery` trong sơ đồ cũ còn tồn tại trong source nhưng không còn phục vụ endpoint trang chủ.

```mermaid
classDiagram
    direction LR

    class AppUser {
        +Guid Id
        +string Email
        +string NormalizedEmail
        +string DisplayName
        +string PartnerCode
        +byte[] PasswordHash
        +byte[] PasswordSalt
        +Guid? PartnerId
        +DateTimeOffset CreatedAt
    }

    class PartnerInvite {
        +Guid Id
        +Guid SenderId
        +Guid RecipientId
        +InviteStatus Status
        +DateTimeOffset CreatedAt
        +DateTimeOffset? RespondedAt
    }

    class InviteStatus {
        <<enumeration>>
        Pending
        Accepted
        Declined
        Cancelled
    }

    class CoupleDbContext {
        +DbSet~AppUser~ Users
        +DbSet~PartnerInvite~ PartnerInvites
    }

    class Couple {
        +Guid Id
        +string DisplayName
        +DateOnly RelationshipStartedOn
        +IReadOnlyCollection~CoupleMember~ Members
        +AddMember(userId, joinedAt)
    }

    class CoupleMember {
        <<record>>
        +Guid UserId
        +DateTimeOffset JoinedAt
        +bool IsActive
        +Leave()
    }

    class RegisterRequest {
        <<record>>
        +string Email
        +string Password
        +string DisplayName
    }

    class LoginRequest {
        <<record>>
        +string Email
        +string Password
    }

    class AuthResponse {
        <<record>>
        +string AccessToken
        +UserProfile User
    }

    class UserProfile {
        <<record>>
        +string DisplayName
        +string PartnerCode
        +PartnerProfile? Partner
    }

    class PartnerProfile {
        <<record>>
        +string DisplayName
        +string PartnerCode
    }

    class SendPartnerInviteRequest {
        <<record>>
        +string PartnerCode
    }

    class PartnerInviteResponse {
        <<record>>
        +Guid Id
        +string FromDisplayName
        +string Status
        +DateTimeOffset CreatedAt
    }

    class SentPartnerInviteResponse {
        <<record>>
        +Guid Id
        +string ToDisplayName
        +DateTimeOffset CreatedAt
    }

    class DashboardSummary {
        <<record>>
        +string CoupleName
        +int DaysTogether
        +int CompletedTasks
        +int TotalTasks
        +IReadOnlyList~DashboardEvent~ TodayEvents
        +PartnerLocationStatus PartnerLocation
    }

    class DashboardEvent {
        <<record>>
        +string Title
        +DateTimeOffset StartsAt
        +string? Place
    }

    class PartnerLocationStatus {
        <<record>>
        +bool IsSharing
        +string? Label
        +DateTimeOffset? UpdatedAt
    }

    class IDashboardQuery {
        <<interface>>
        +DashboardSummary GetDemo()
    }

    class DemoDashboardQuery {
        +DashboardSummary GetDemo()
    }

    class AuthApi {
        +register(name, email, password)
        +login(email, password)
        +restore()
        +me(token)
        +sendInvite(token, partnerCode)
        +acceptInvite(token, inviteId)
        +declineInvite(token, inviteId)
        +cancelInvite(token, inviteId)
        +signOut()
    }

    class SessionController {
        +AppUserProfile? user
        +String? token
        +bool loading
        +restore()
        +login(email, password)
        +register(name, email, password)
        +refreshProfile()
        +signOut()
    }

    class AppUserProfile {
        +String displayName
        +String partnerCode
        +PartnerProfile? partner
    }

    class PartnerInviteModel {
        +String id
        +String fromDisplayName
    }

    class SentPartnerInvite {
        +String id
        +String toDisplayName
    }

    CoupleDbContext "1" --> "0..*" AppUser : stores
    CoupleDbContext "1" --> "0..*" PartnerInvite : stores
    AppUser "0..1" --> "0..1" AppUser : PartnerId / partner
    AppUser "1" <-- "0..*" PartnerInvite : sender
    AppUser "1" <-- "0..*" PartnerInvite : recipient
    PartnerInvite --> InviteStatus
    Couple "1" *-- "0..2" CoupleMember : members
    CoupleMember ..> AppUser : UserId (Guid)
    AuthResponse *-- UserProfile
    UserProfile o-- PartnerProfile
    PartnerInviteResponse --> InviteStatus : status value
    SentPartnerInviteResponse ..> PartnerInvite : response DTO
    IDashboardQuery <|.. DemoDashboardQuery
    DashboardSummary *-- DashboardEvent
    DashboardSummary *-- PartnerLocationStatus
    SessionController --> AuthApi : calls
    SessionController o-- AppUserProfile : current session
    AuthApi ..> RegisterRequest : sends
    AuthApi ..> LoginRequest : sends
    AuthApi ..> SendPartnerInviteRequest : sends
    AuthApi ..> PartnerInviteModel : parses
    AuthApi ..> SentPartnerInvite : parses
    AuthApi ..> AuthResponse : parses
```

Lưu ý: domain `Couple`/`CoupleMember` chưa được map vào `CoupleDbContext`. `Members` có thể chứa nhiều thành viên lịch sử, với tối đa hai thành viên đang hoạt động; giới hạn `0..2` ở trên chỉ mô tả thành viên đang hoạt động. Chia sẻ vị trí vẫn chưa được triển khai.

## Workspace — bổ sung tháng 11/2026

```mermaid
classDiagram
    class AppUser {
        +Guid Id
        +Guid? PartnerId
    }
    class WorkspaceTask {
        +Guid Id
        +Guid OwnerId
        +Guid? SharedWithUserId
        +string Title
        +string? Notes
        +bool IsComplete
        +string Priority
        +DateTimeOffset? DueAt
        +DateTimeOffset CreatedAt
        +DateTimeOffset UpdatedAt
    }
    class CalendarEvent {
        +Guid Id
        +Guid OwnerId
        +Guid? SharedWithUserId
        +string Title
        +string? Notes
        +string? Location
        +DateTimeOffset StartsAt
        +DateTimeOffset EndsAt
        +DateTimeOffset CreatedAt
        +DateTimeOffset UpdatedAt
    }
    class CoupleDbContext
    class WorkspaceController {
        +tasks
        +events
        +loading
        +busy
        +error
        +refresh()
        +saveTask()
        +saveEvent()
        +toggleTask()
        +removeTask()
        +removeEvent()
    }
    class WorkspaceApi
    class HomeScreen
    class TasksScreen
    class CalendarScreen
    AppUser "1" <-- "0..*" WorkspaceTask : owner
    AppUser "0..1" <-- "0..*" WorkspaceTask : sharedWith
    AppUser "1" <-- "0..*" CalendarEvent : owner
    AppUser "0..1" <-- "0..*" CalendarEvent : sharedWith
    CoupleDbContext --> WorkspaceTask : stores
    CoupleDbContext --> CalendarEvent : stores
    WorkspaceController --> WorkspaceApi : HTTP requests
    HomeScreen --> WorkspaceController
    TasksScreen --> WorkspaceController
    CalendarScreen --> WorkspaceController
```

`sharedWith` chỉ có hiệu lực khi hai tài khoản vẫn đang kết nối hai chiều. Model
Flutter ánh xạ các response tương ứng; `createdByMe` do server tính để giao diện
chỉ cho người tạo thay đổi chế độ chia sẻ.
