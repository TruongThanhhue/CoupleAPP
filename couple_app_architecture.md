# Couple App — Ý tưởng sản phẩm & Kiến trúc tổng thể

> **One place for two lives.**
>
> Couple App là một ứng dụng dành riêng cho hai người trong một mối quan hệ, tập trung vào việc quản lý cuộc sống chung: sức khỏe cá nhân có thể chia sẻ, công việc và lịch trình, vị trí, kỷ niệm, chi tiêu và các tiện ích dành cho cặp đôi.

---

## 1. Tầm nhìn sản phẩm

Couple App không chỉ là một ứng dụng “theo dõi người yêu”, mà hướng đến một **shared life app / private operating system for two people**.

Ứng dụng xoay quanh thực thể trung tâm là `Couple`.

```text
                    COUPLE APP
                         │
               ┌─────────▼─────────┐
               │       COUPLE      │
               └─────────┬─────────┘
                         │
       ┌─────────────────┼─────────────────┐
       │                 │                 │
     HEALTH           PLANNER           LOCATION
       │                 │                 │
     Cycle           Tasks/Calendar       Map
       │                 │                 │
       └─────────────────┼─────────────────┘
                         │
              ┌──────────┼──────────┐
              │          │          │
           Memories   Expenses   Shopping
```

### Giá trị cốt lõi

- Quản lý cuộc sống của hai người trong một không gian riêng tư.
- Đồng bộ công việc và lịch trình của hai người.
- Chia sẻ vị trí có kiểm soát.
- Theo dõi chu kỳ kinh nguyệt cho người có nhu cầu.
- Lưu lại kỷ niệm và các cột mốc của mối quan hệ.
- Theo dõi chi tiêu và các hoạt động chung.

---

# 2. Nguyên tắc thiết kế quan trọng

## 2.1. Không hard-code tính năng chu kỳ theo giới tính của cặp đôi

Không nên viết business rule kiểu:

```text
male + female  -> cycle tracking
female + female -> cycle tracking
male + male    -> no cycle tracking
```

Thay vào đó, mỗi tài khoản có quyền cấu hình riêng:

```text
User
├── cycleTrackingEnabled
├── locationSharingEnabled
└── ...
```

Ví dụ:

### Cặp nam + nữ

```text
User A
cycleTrackingEnabled = false

User B
cycleTrackingEnabled = true
```

### Cặp nữ + nữ

```text
User A
cycleTrackingEnabled = true

User B
cycleTrackingEnabled = true
```

### Cặp nam + nam

```text
User A
cycleTrackingEnabled = false

User B
cycleTrackingEnabled = false
```

Cách này linh hoạt, tránh hard-code và dễ mở rộng trong tương lai.

---

# 3. Các module chính

Couple App gồm các module sau:

```text
Couple App
│
├── Authentication
├── Couple Management
├── Home Dashboard
├── Menstrual / Cycle Tracking
├── Task Management
├── Calendar
├── Google Calendar Integration
├── Google Tasks Integration
├── Location Sharing
├── Memories
├── Expenses
├── Shopping List
├── Anniversary / Countdown
├── Couple Planner
├── Check-in
├── Notifications
├── Settings
└── Privacy & Security
```

> **Đã loại bỏ theo yêu cầu:** `Care Mode` và `Couple Chat`.

---

# 4. Module 1 — Authentication

Hỗ trợ:

- Register
- Login
- Logout
- Refresh token
- Google Login
- Forgot password
- Change password
- Email verification
- Quản lý thiết bị đăng nhập

API gợi ý:

```http
POST /api/auth/register
POST /api/auth/login
POST /api/auth/refresh
POST /api/auth/logout
POST /api/auth/google
POST /api/auth/forgot-password
POST /api/auth/reset-password
```

---

# 5. Module 2 — Couple Management

Người dùng có thể:

1. Tạo Couple.
2. Tạo invitation code.
3. Gửi link/mã mời cho người yêu.
4. Người còn lại tham gia Couple.
5. Xem thông tin thành viên.
6. Rời Couple.
7. Hủy liên kết Couple.

Mô hình:

```text
User A
   │
   ├──── CoupleMember ────┐
   │                      │
   │                    Couple
   │                      │
   └──── CoupleMember ────┤
                          │
                        User B
```

API:

```http
POST /api/couples
POST /api/couples/invite
POST /api/couples/join
GET  /api/couples/me
GET  /api/couples/members
DELETE /api/couples/me
```

---

# 6. Module 3 — Couple Home Dashboard

Đây là màn hình trung tâm của app.

Ví dụ bố cục:

```text
┌─────────────────────────────────┐
│           ❤️ COUPLE             │
│                                 │
│       User A ❤️ User B          │
│       Together 1,248 days       │
│                                 │
├─────────────────────────────────┤
│ TODAY                           │
│                                 │
│ 📅 19:00 Dinner                │
│ ✅ 3/5 Tasks                    │
│ 📍 Partner: University         │
│ 📍 You: Home                   │
│                                 │
├─────────────────────────────────┤
│ HEALTH                          │
│                                 │
│ 🩸 Cycle                        │
│ Next estimated period: 24/10   │
│                                 │
├─────────────────────────────────┤
│ QUICK ACTIONS                   │
│                                 │
│ [Task] [Calendar] [Location]   │
│ [Memory] [Expense] [Check-in]  │
└─────────────────────────────────┘
```

Dashboard lấy dữ liệu từ nhiều module:

```text
Home
├── Today's Tasks
├── Upcoming Events
├── Current/Last Location
├── Cycle Summary
├── Anniversary Countdown
├── Recent Memories
└── Expense Summary
```

---

# 7. Module 4 — Menstrual / Cycle Tracking

## 7.1. Mục tiêu

Cho phép từng người tự quản lý chu kỳ và có thể chia sẻ cho partner nếu bật quyền.

## 7.2. Chức năng

- Bật/tắt cycle tracking.
- Ghi ngày bắt đầu kỳ kinh.
- Ghi ngày kết thúc.
- Lưu độ dài chu kỳ.
- Lưu độ dài kỳ kinh.
- Lưu lịch sử các chu kỳ.
- Ghi mức độ dòng chảy.
- Ghi mức độ đau.
- Ghi chú cá nhân.
- Dự báo kỳ tiếp theo.
- Xem lịch chu kỳ.
- Xem thống kê.
- Chia sẻ cho partner hoặc giữ riêng tư.

## 7.3. Database

```text
CycleProfile
------------
Id
UserId
AverageCycleLength
AveragePeriodLength
TrackingEnabled
CreatedAt
UpdatedAt
```

```text
PeriodEntry
-----------
Id
CycleProfileId
StartDate
EndDate
FlowLevel
PainLevel
Notes
CreatedAt
UpdatedAt
```

## 7.4. Quyền riêng tư

```text
CycleVisibility
---------------
PRIVATE
PARTNER
```

Luồng kiểm tra:

```text
User A
  ↓
CoupleMember
  ↓
User B
  ↓
CycleTrackingEnabled?
  ↓
CycleVisibility == PARTNER?
  ↓
ALLOW / DENY
```

## 7.5. Dự báo chu kỳ

### MVP

Dùng phương pháp thống kê đơn giản trước, không cần Machine Learning ngay.

Ví dụ:

```text
Chu kỳ lịch sử:
28 ngày
29 ngày
29 ngày
```

```text
Average = (28 + 29 + 29) / 3
       = 28.67 ngày
```

Ngày dự kiến:

```text
LastPeriodStart + AverageCycleLength
```

### Phiên bản nâng cao

```text
Simple Average
      ↓
Moving Average
      ↓
Weighted Moving Average
      ↓
Bayesian / Personalized Model
      ↓
Prediction with uncertainty range
```

Nên lưu cả dự báo và ngày thực tế để đánh giá độ lệch:

```text
Prediction
----------
ExpectedStart
EarliestStart
LatestStart
Confidence
GeneratedAt
```

Trong UI nên mô tả đây là **ước tính**, không phải chẩn đoán y khoa hoặc phương pháp tránh thai.

---

# 8. Module 5 — Tasks / Todo List

## 8.1. Chức năng

- My Tasks
- Partner Tasks
- Shared Tasks
- Assign task cho partner
- Deadline
- Priority
- Mark complete
- Overdue
- Today
- Upcoming
- Filter theo người thực hiện

Ví dụ:

```text
TODAY

☐ Mua đồ ăn           → User A
☐ Đặt vé xem phim     → User B
☐ Dọn phòng           → Both
```

## 8.2. Database

```text
Task
----
Id
CoupleId
Title
Description
AssignedToUserId
CreatedByUserId
DueDate
Priority
Status
Source
ExternalId
CreatedAt
UpdatedAt
```

`Source`:

```text
INTERNAL
GOOGLE_TASKS
```

---

# 9. Module 6 — Google Tasks Integration

Couple App nên có **database task riêng**, Google Tasks đóng vai trò integration/mirror.

Kiến trúc:

```text
             COUPLE APP
                  │
          Shared Task Database
                  │
       ┌──────────┴──────────┐
       │                     │
   Google Tasks A        Google Tasks B
```

Ví dụ:

```text
Couple App
"Ngày mai mua hoa"
AssignedTo = User A
```

Được đồng bộ sang Google Tasks của User A.

Nếu người dùng hoàn thành task trên Google Tasks:

```text
Google Tasks
     ↓
Sync Worker
     ↓
Couple Database
     ↓
SignalR
     ↓
Partner App
```

### Database integration

```text
GoogleConnection
----------------
Id
UserId
Provider
GoogleAccountId
AccessTokenEncrypted
RefreshTokenEncrypted
TokenExpiresAt
Status
CreatedAt
UpdatedAt
```

Có thể lưu mapping giữa task nội bộ và task Google bằng `ExternalId`.

---

# 10. Module 7 — Calendar

## 10.1. Internal Calendar

Cho phép hai người tạo và xem các event chung:

```text
Date
Time
Title
Description
Location
CreatedBy
Participants
```

## 10.2. Google Calendar

Hỗ trợ:

- Kết nối tài khoản Google.
- Chọn calendar để đồng bộ.
- Import event.
- Export/shared event.
- Đồng bộ thay đổi.
- Theo dõi trạng thái sync.

Kiến trúc:

```text
             Couple App
                  │
            Calendar Module
                  │
       ┌──────────┴──────────┐
       │                     │
Google Calendar A      Google Calendar B
```

---

# 11. Module 8 — Couple Planner

Đây là màn hình tổng hợp lịch sống chung.

```text
                THIS WEEK

MON
✅ Study
✅ Grocery

TUE
📅 Class
📅 Date Night

WED
✅ Clean Room

THU
📍 University

FRI
❤️ Movie Night
```

Dữ liệu lấy từ:

```text
Internal Events
Google Calendar
Couple Tasks
Google Tasks
Anniversaries
Cycle reminders
```

Planner giúp Couple App trở thành ứng dụng quản lý cuộc sống chung thay vì chỉ là tập hợp các CRUD screen.

---

# 12. Module 9 — Location Sharing

## 12.1. Chức năng

- Last seen location.
- Live location.
- Share location trong khoảng thời gian giới hạn.
- Location history.
- Check-in.
- Saved places.
- Geofence.
- Arrival notification.
- Leave-place notification.
- Bật/tắt sharing.

## 12.2. Sharing modes

```text
OFF
LAST_SEEN
LIVE
LIVE_FOR_15_MIN
LIVE_FOR_1_HOUR
```

## 12.3. Luồng realtime

```text
Phone
  ↓
Location Service
  ↓
Location Manager
  ↓
Adaptive Update
  ↓
ASP.NET Core
  ↓
SignalR
  ↓
Partner App
```

Không nên gửi GPS mỗi giây mặc định.

Nên dùng adaptive update dựa trên:

- khoảng cách di chuyển,
- tốc độ,
- trạng thái live location,
- mức pin,
- tần suất cần thiết.

## 12.4. Database

```text
LocationSharingSession
-----------------------
Id
CoupleId
UserId
Mode
StartedAt
ExpiresAt
IsActive
```

```text
LocationPoint
-------------
Id
SessionId
Latitude
Longitude
Accuracy
Speed
Heading
RecordedAt
```

## 12.5. Saved Places

```text
Place
-----
Id
UserId
Name
Latitude
Longitude
Radius
Type
```

Ví dụ:

```text
Home
University
Company
Gym
Favorite Cafe
```

## 12.6. Arrival notification

Ví dụ:

```text
Partner enters 100m radius of University
                ↓
          Geofence event
                ↓
           Notification
                ↓
      "Partner has arrived ❤️"
```

---

# 13. Module 10 — Memories

Album riêng của Couple.

```text
Memories
├── 2026
│   ├── January
│   ├── February
│   ├── March
│   └── ...
```

Mỗi memory có thể gồm:

```text
Photo
Caption
Location
Date
Tags
```

Tính năng nâng cao:

- Monthly memories.
- Anniversary memories.
- Timeline.
- Favorite memories.
- Shared album.

---

# 14. Module 11 — Anniversary / Countdown

Các mốc:

```text
RelationshipStartDate
Anniversary
Birthday
FirstMeet
FirstDate
CustomEvent
```

UI:

```text
❤️ 1,248 days together

Next anniversary:
83 days
```

---

# 15. Module 12 — Shared Expenses

Cho phép quản lý các khoản chi chung.

Ví dụ:

```text
Pizza       250,000đ
Movie       180,000đ
Travel      600,000đ
```

```text
Total = 1,030,000đ

User A paid = 450,000đ
User B paid = 580,000đ

50/50 split
→ User B owes User A: 65,000đ
```

Database:

```text
Expense
-------
Id
CoupleId
PaidBy
Amount
Category
Description
Date
CreatedAt
UpdatedAt
```

Có thể mở rộng:

```text
ExpenseParticipant
------------------
ExpenseId
UserId
ShareAmount
```

để hỗ trợ chia tỷ lệ linh hoạt.

---

# 16. Module 13 — Shared Shopping List

Ví dụ:

```text
🛒 Grocery

☐ Sữa
☐ Trứng
☐ Rau
☐ Coca
☑ Bánh mì
```

Hỗ trợ realtime:

```text
User A checks item
        ↓
Backend
        ↓
SignalR
        ↓
User B sees update
```

Có thể mở rộng thành:

```text
ShoppingList
ShoppingItem
Quantity
Assignee
Completed
```

---

# 17. Module 14 — Couple Check-in

Một cách để người dùng cập nhật trạng thái ngắn gọn.

Ví dụ:

```text
😊 Good
😐 Normal
😴 Tired
😔 Bad day
🏠 Home
🚗 On the way
```

Có thể hiển thị trên Couple Home:

```text
Partner
😊 Good day
📍 At home
```

Check-in phải là dữ liệu người dùng chủ động chia sẻ, không tự động suy đoán trạng thái cảm xúc.

---

# 18. Module 15 — Notifications

Thông báo có thể phát sinh từ:

```text
Task assigned
Task due
Task completed
Calendar event approaching
Cycle reminder
Cycle prediction generated
Partner arrived
Partner left place
Location sharing started/stopped
Anniversary approaching
Expense added
Shopping item changed
```

Kiến trúc:

```text
Controller / Service
        ↓
Domain Event
        ↓
Notification Queue
        ↓
Notification Worker
        ↓
FCM / APNs
```

---

# 19. Kiến trúc tổng thể

## 19.1. High-level architecture

```text
                    ┌───────────────────────┐
                    │      Flutter App      │
                    │      Android/iOS      │
                    └───────────┬───────────┘
                                │
                         HTTPS REST API
                          + SignalR
                                │
                    ┌───────────▼───────────┐
                    │   ASP.NET Core 10     │
                    │    Modular Monolith   │
                    └───────────┬───────────┘
                                │
      ┌─────────────────────────┼─────────────────────────┐
      │                         │                         │
      ▼                         ▼                         ▼
┌─────────────┐          ┌─────────────┐          ┌─────────────┐
│    Auth     │          │   Couple    │          │  Location   │
│   Module    │          │   Module    │          │   Module    │
└─────────────┘          └─────────────┘          └─────────────┘
      │                         │                         │
      ▼                         ▼                         ▼
┌─────────────┐          ┌─────────────┐          ┌─────────────┐
│   Cycles    │          │   Tasks     │          │   SignalR   │
│   Module    │          │   Module    │          │    Hub      │
└─────────────┘          └─────────────┘          └─────────────┘
      │                         │
      └──────────────┬──────────┘
                     ▼
             ┌───────────────┐
             │ PostgreSQL    │
             │ + PostGIS     │
             └───────────────┘
                     │
               ┌─────┴─────┐
               ▼           ▼
          ┌─────────┐ ┌──────────────┐
          │  Redis  │ │ Object       │
          │  Cache  │ │ Storage      │
          └─────────┘ └──────────────┘

       EXTERNAL INTEGRATIONS

       ┌─────────────────────────┐
       │ Google Calendar         │
       ├─────────────────────────┤
       │ Google Tasks            │
       └───────────┬─────────────┘
                   │
                   ▼
            ┌───────────────┐
            │  Sync Worker  │
            │ / Hangfire    │
            └───────────────┘

            ┌───────────────┐
            │ FCM / APNs    │
            │ Notifications │
            └───────────────┘
```

---

# 20. Tại sao chọn Modular Monolith?

Không nên bắt đầu bằng microservices ngay từ đầu.

Tránh kiến trúc quá phức tạp như:

```text
Auth Service
Couple Service
Cycle Service
Location Service
Task Service
Calendar Service
Memory Service
Expense Service
Notification Service
...
```

Điều đó tạo thêm gánh nặng cho:

- Docker orchestration.
- Service discovery.
- Distributed transactions.
- Message queues.
- Monitoring.
- Deployment.
- Authentication giữa service.

MVP phù hợp hơn với:

```text
ASP.NET Core
│
├── Auth
├── Couples
├── Cycles
├── Tasks
├── Calendar
├── Google Integrations
├── Location
├── Memories
├── Expenses
├── Shopping
├── Check-in
└── Notifications
```

Sau này các thành phần có tải cao có thể tách riêng:

```text
Location Service
Sync Worker
Notification Worker
```

---

# 21. Backend Architecture

Đề xuất:

```text
backend/
└── CoupleApp.sln
    │
    ├── CoupleApp.API/
    ├── CoupleApp.Application/
    ├── CoupleApp.Domain/
    ├── CoupleApp.Infrastructure/
    │
    └── Modules/
        ├── Auth/
        ├── Couples/
        ├── Cycles/
        ├── Tasks/
        ├── Calendar/
        ├── Google/
        ├── Location/
        ├── Memories/
        ├── Expenses/
        ├── Shopping/
        ├── Checkin/
        └── Notifications/
```

Có thể tổ chức mỗi module theo kiểu:

```text
ModuleName/
├── Domain/
├── Application/
├── Infrastructure/
└── API/
```

---

# 22. Flutter Architecture

```text
mobile/
└── couple_app/
    ├── lib/
    │   ├── core/
    │   │   ├── network/
    │   │   ├── storage/
    │   │   ├── theme/
    │   │   ├── routing/
    │   │   └── utils/
    │   │
    │   ├── features/
    │   │   ├── auth/
    │   │   ├── couple/
    │   │   ├── home/
    │   │   ├── cycle/
    │   │   ├── tasks/
    │   │   ├── calendar/
    │   │   ├── location/
    │   │   ├── memories/
    │   │   ├── expenses/
    │   │   ├── shopping/
    │   │   ├── checkin/
    │   │   └── settings/
    │   │
    │   └── main.dart
    │
    └── test/
```

---

# 23. Database Architecture

Các entity chính:

```text
Users
 │
 ├── UserSettings
 ├── CycleProfiles
 │     └── PeriodEntries
 ├── LocationSettings
 ├── LocationSharingSessions
 │     └── LocationPoints
 ├── GoogleConnections
 └── Devices

Couples
 │
 ├── CoupleMembers
 ├── Tasks
 ├── Events
 ├── Memories
 ├── Expenses
 ├── ShoppingLists
 ├── Places
 ├── CheckIns
 └── Notifications
```

Quan hệ tổng quát:

```text
User
 │
 ├──────────────< CoupleMember >────────────── Couple
 │                                               │
 │                                               ├── Tasks
 │                                               ├── Events
 │                                               ├── Memories
 │                                               ├── Expenses
 │                                               ├── ShoppingLists
 │                                               ├── Places
 │                                               └── CheckIns
 │
 ├── CycleProfile
 │       └── PeriodEntry
 │
 ├── LocationSharingSession
 │       └── LocationPoint
 │
 └── GoogleConnection
```

---

# 24. API Design

## Authentication

```http
POST /api/auth/register
POST /api/auth/login
POST /api/auth/refresh
POST /api/auth/logout
POST /api/auth/google
```

## Couple

```http
POST /api/couples
POST /api/couples/invite
POST /api/couples/join
GET  /api/couples/me
GET  /api/couples/members
DELETE /api/couples/me
```

## Cycle

```http
POST /api/cycles/profile
GET  /api/cycles/me
POST /api/cycles/periods
PUT  /api/cycles/periods/{id}
DELETE /api/cycles/periods/{id}
GET /api/cycles/prediction
GET /api/couples/cycle
```

## Tasks

```http
GET    /api/tasks
POST   /api/tasks
PUT    /api/tasks/{id}
DELETE /api/tasks/{id}
POST   /api/tasks/{id}/complete
POST   /api/tasks/{id}/assign
```

## Calendar / Google

```http
GET  /api/integrations/google/connect
GET  /api/integrations/google/callback
GET  /api/integrations/google/calendars
POST /api/integrations/google/calendar/sync
POST /api/integrations/google/tasks/sync
DELETE /api/integrations/google
```

## Location

```http
POST /api/location/session/start
POST /api/location/session/stop
POST /api/location/ping
GET  /api/location/partner
GET  /api/location/history
```

---

# 25. SignalR / Realtime

SignalR dùng cho các chức năng cần cập nhật tức thời:

```text
Task changed
      ↓
SignalR
      ↓
Partner UI updates
```

```text
Location changed
      ↓
SignalR
      ↓
Partner Map updates
```

```text
Check-in changed
      ↓
SignalR
      ↓
Partner UI updates
```

Ví dụ Hub:

```text
CoupleHub
├── JoinCouple(coupleId)
├── TaskUpdated(...)
├── SendLocation(...)
├── CheckIn(...)
└── NotifyPartner(...)
```

---

# 26. Google Sync Architecture

Google integration nên tách khỏi request/response trực tiếp của API.

```text
             Google APIs
                  │
                  ▼
           ┌─────────────┐
           │ Sync Worker │
           └──────┬──────┘
                  │
        ┌─────────┴─────────┐
        ▼                   ▼
 Calendar Sync         Tasks Sync
        │                   │
        └─────────┬─────────┘
                  ▼
             Couple DB
                  │
                  ▼
               SignalR
```

Nguyên tắc:

- Couple App giữ database nội bộ làm nguồn dữ liệu chính cho shared data.
- Google Calendar / Google Tasks là integration.
- Dùng mapping `ExternalId` để đối chiếu dữ liệu.
- Sync theo thay đổi thay vì tải lại toàn bộ dữ liệu nếu API hỗ trợ incremental sync.
- OAuth token phải được bảo vệ và mã hóa khi lưu phía server.

---

# 27. Security & Privacy Architecture

Couple App sẽ chứa nhiều dữ liệu nhạy cảm:

```text
❤️ Relationship data
🩸 Menstrual data
📍 Location data
📅 Calendar data
✅ Tasks
📷 Memories
💰 Expenses
```

Do đó security phải là core feature.

## Tối thiểu

```text
HTTPS
JWT Access Token
Refresh Token Rotation
Password Hashing
Input Validation
Rate Limiting
SQL Injection Protection
RBAC
Audit Log
Encrypted OAuth Tokens
Secure Local Storage
```

## Private / Couple / Integration Data

Nên phân lớp dữ liệu:

```text
PRIVATE DATA
│
├── My cycle
├── My location history
├── My private notes
└── My Google data

COUPLE DATA
│
├── Shared tasks
├── Shared events
├── Memories
├── Expenses
├── Shopping
└── Check-ins

SYNC DATA
│
├── Google Calendar mapping
├── Google Tasks mapping
└── Sync state / tokens
```

---

# 28. Location Privacy Model

Cài đặt đề xuất:

```text
Location Sharing

[ ON ]

Who can see:
● Partner

Mode:
● Last Seen
○ Live

History:
○ Don't save
● 24 hours
○ 7 days
○ 30 days

Auto-share:
☐ When leaving home
☐ When arriving home
```

Luôn có nút:

```text
🛑 STOP SHARING
```

Người dùng phải biết rõ khi nào vị trí đang được chia sẻ.

---

# 29. Navigation / Màn hình chính

Đề xuất Navigation Bar:

```text
┌──────────────────────────────────┐
│                                  │
│             HOME                 │
│                                  │
├──────────────────────────────────┤
│                                  │
│  🏠 Home                         │
│  📅 Calendar                     │
│  ✅ Tasks                        │
│  📍 Location                     │
│  ❤️ Memories                     │
│                                  │
├──────────────────────────────────┤
│  More                            │
│                                  │
│  🩸 Cycle                        │
│  💰 Expenses                     │
│  🛒 Shopping                     │
│  ❤️ Countdown                    │
│  😊 Check-in                     │
│  ⚙ Settings                      │
└──────────────────────────────────┘
```

Có thể điều chỉnh lại thành 4–5 tab chính trên mobile và đưa các module còn lại vào `More`.

---

# 30. MVP Roadmap

## MVP v0.1 — Core Couple

```text
✅ Register / Login
✅ Google Login
✅ Create Couple
✅ Invite Partner
✅ Join Couple
✅ Couple Home
✅ Shared Tasks
✅ Internal Calendar
✅ Basic Cycle Tracking
✅ Cycle Prediction
✅ Push Notifications
```

## v0.2 — Integrations

```text
✅ Google Calendar
✅ Google Tasks
✅ Realtime Tasks
✅ Better Planner
✅ Anniversary / Countdown
✅ Shared Shopping List
```

## v0.3 — Location

```text
✅ Last Seen
✅ Live Location
✅ Time-limited sharing
✅ Check-in
✅ Saved Places
✅ Geofence
✅ Arrival Notification
```

## v1.0 — Full Couple Workspace

```text
✅ Memories
✅ Expenses
✅ Advanced cycle statistics
✅ Couple Planner
✅ Data backup
✅ Data export
✅ Privacy Center
✅ Security hardening
✅ Performance optimization
✅ App widgets / shortcuts
```

---

# 31. Thứ tự lập trình thực tế

Nên triển khai theo thứ tự:

```text
STEP 01
Database + Entity Model
        ↓
STEP 02
ASP.NET Core + Identity + JWT
        ↓
STEP 03
Flutter Login/Register
        ↓
STEP 04
Couple Create / Invite / Join
        ↓
STEP 05
Couple Home
        ↓
STEP 06
Shared Tasks
        ↓
STEP 07
Internal Calendar
        ↓
STEP 08
Cycle Tracking
        ↓
STEP 09
Cycle Prediction
        ↓
STEP 10
Notifications
        ↓
STEP 11
Google Calendar
        ↓
STEP 12
Google Tasks
        ↓
STEP 13
SignalR / Realtime
        ↓
STEP 14
Location Sharing
        ↓
STEP 15
Memories / Expenses / Shopping / Check-in
        ↓
STEP 16
Security + Privacy + Testing
        ↓
STEP 17
Deployment
```

---

# 32. Stack công nghệ đề xuất

| Thành phần | Công nghệ |
|---|---|
| Mobile | Flutter |
| Language | Dart |
| Backend | ASP.NET Core 10 |
| Backend language | C# |
| ORM | Entity Framework Core |
| Database | PostgreSQL |
| GIS | PostGIS |
| Realtime | SignalR |
| Cache | Redis |
| Background jobs | Hangfire / Worker Service |
| Authentication | ASP.NET Identity + JWT + Google OAuth |
| Calendar | Google Calendar API |
| Todo | Google Tasks API |
| Push | Firebase Cloud Messaging + APNs |
| Map | Google Maps SDK hoặc Mapbox |
| File/Image storage | S3-compatible Object Storage |
| Deployment | Docker |
| CI/CD | GitHub Actions |

---

# 33. Những chức năng có thể bổ sung trong tương lai

Các ý tưởng mở rộng nhưng chưa cần làm trong MVP:

```text
AI Couple Assistant
Smart weekly planning
Automatic monthly memories
Budget analytics
Expense trends
Advanced location analytics
Home screen widgets
Wearable integration
Apple Health / Google Health Connect
Shared goals
Habit tracking
Travel planner
Date planner
Gift reminders
Relationship milestones
```

AI Couple Assistant có thể trả lời những câu hỏi dựa trên dữ liệu mà người dùng đã cấp quyền, ví dụ:

```text
"Cuối tuần này chúng tôi có thời gian rảnh cùng nhau lúc nào?"
```

và sử dụng:

```text
Google Calendar
+
Couple Tasks
+
Internal Events
```

để đề xuất các khoảng thời gian trống.

---

# 34. Product structure cuối cùng

Couple App có thể được nhìn như 6 nhóm giá trị chính:

```text
                    COUPLE APP
                         │
 ┌───────────────────────┼───────────────────────┐
 │                       │                       │
 ▼                       ▼                       ▼
❤️ RELATIONSHIP       🩸 HEALTH               📅 PLANNING
 │                       │                       │
 ├── Countdown           └── Cycle              ├── Tasks
 ├── Memories                                    ├── Calendar
 └── Milestones                                  └── Shopping

 ┌───────────────────────┼───────────────────────┐
 │                       │                       │
 ▼                       ▼                       ▼
📍 LOCATION            💰 FINANCE             🔒 PRIVACY
 │                       │                       │
 ├── Live Location       ├── Expenses           ├── Permissions
 ├── Last Seen           └── Split              ├── Visibility
 ├── Places                                      └── Security
 └── Geofence
```

---

# 35. Kết luận kiến trúc

Kiến trúc đề xuất cho Couple App:

```text
Flutter
   ↓
ASP.NET Core 10 Modular Monolith
   ↓
PostgreSQL + PostGIS
   ↓
Redis
   ↓
SignalR
   ↓
Background Workers
   ↓
Google Calendar / Google Tasks
   ↓
FCM / APNs
```

Ba trục tính năng chính:

```text
        ❤️ RELATIONSHIP
               │
       ┌───────┼────────┐
       ▼       ▼        ▼
    MEMORIES  EVENTS  COUNTDOWN

        🧠 DAILY LIFE
               │
       ┌───────┼────────┐
       ▼       ▼        ▼
     TASKS   CALENDAR  SHOPPING

        📍 PERSONAL DATA
               │
       ┌───────┼────────┐
       ▼       ▼        ▼
      CYCLE  LOCATION  EXPENSES
```

Mục tiêu của MVP không phải tạo một ứng dụng có thật nhiều tính năng, mà xây dựng một **core Couple workspace** đủ tốt để các module sau này có thể kết nối vào mà không phải viết lại kiến trúc.

---

# 36. Recommended first milestone

Milestone đầu tiên nên đạt trạng thái:

```text
User A
   ↓
Register/Login
   ↓
Create Couple
   ↓
Invite User B
   ↓
User B joins
   ↓
Couple Home appears
   ↓
Shared Tasks work
   ↓
Internal Calendar works
   ↓
Cycle Tracking works
   ↓
Prediction works
```

Khi milestone này hoàn thành, Couple App đã có một nền tảng sản phẩm hoàn chỉnh để tiếp tục phát triển Google integration, realtime và location mà không phải phá lại kiến trúc cốt lõi.
