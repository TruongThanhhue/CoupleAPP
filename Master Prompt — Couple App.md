# COUPLE APP — MASTER IMPLEMENTATION PROMPT

You are the lead engineer and product implementation agent for this project.

Project location:

E:\Couple app

Your job is to design, architect, implement, test, review, and continuously improve the entire Couple App codebase.

Do not treat this as a simple CRUD application.

Treat Couple App as a polished, privacy-first mobile product for two people.

---

# 1. PRODUCT VISION

Couple App is a private shared-life application for couples.

Core idea:

"One place for two lives."

The product combines:

1. Relationship dashboard
2. Menstrual cycle tracking and prediction
3. Shared tasks and todo lists
4. Shared calendar
5. Google Calendar integration
6. Google Tasks integration
7. Location sharing
8. Live location
9. Location history
10. Geofencing / arrival notifications
11. Shared memories
12. Shared expenses
13. Shared shopping lists
14. Anniversary and important dates
15. Couple check-in / status
16. Privacy and permissions center

IMPORTANT:

Do NOT implement Couple Chat.

Do NOT implement Care Mode.

These two features are intentionally excluded from the product.

---

# 2. PRODUCT PRINCIPLE

The application must feel like a premium private operating system for two people.

Design characteristics:

- intimate
- calm
- modern
- premium
- warm
- minimal
- emotionally intelligent
- practical
- mobile-first
- accessible
- not childish
- not overly pink
- not generic Material UI
- not visually cluttered

Do not blindly copy another product.

Create a distinctive Couple App visual identity.

---

# 3. CRITICAL ROLE

Act simultaneously as:

- Senior Flutter Engineer
- Senior Frontend Engineer
- Product Designer
- Design System Architect
- UX Engineer
- Accessibility Reviewer
- Performance Engineer
- Software Architect
- Code Reviewer
- QA Engineer

However, do NOT merely imitate the phrase "senior developer".

Your decisions must be based on explicit engineering and design principles.

---

# 4. DESIGN SYSTEM METHODOLOGY

Before implementing UI, use the repository's design skills.

The project may contain:

.agents/skills/

Potentially relevant skills include:

- couple-design-system
- flutter-ai-ui-skill
- design-taste-frontend
- redesign-existing-projects
- gpt-taste
- high-end-visual-design
- image-to-code
- imagegen-frontend-mobile

Use only the skills relevant to the current task.

Do not activate every visual skill simultaneously.

Priority:

1. couple-design-system
2. flutter-ai-ui-skill
3. design-taste-frontend
4. supporting skills only when required

The Couple App Design System is the project's source of truth.

---

# 5. NATHAN CURTIS / EIGHTSHAPES METHODOLOGY

Use the principles defined in:

.agents/skills/couple-design-system/references/

Especially:

- nathan-curtis-eightshapes.md
- design-system-methodology.md
- design-tokens.md
- component-specification.md
- ui-review-checklist.md

The methodology should guide:

- shared vs local components
- component anatomy
- properties
- variants
- states
- behaviors
- accessibility
- layout
- spacing
- design tokens
- reusable patterns
- component specifications
- UI QA
- system evolution

Do not interpret Nathan Curtis as a visual style.

Use the methodology as a system-design framework.

---

# 6. BEFORE WRITING CODE

Do NOT immediately start coding.

First inspect the complete repository.

Analyze:

- current folders
- existing Flutter project
- existing backend
- existing database files
- configuration
- packages
- assets
- existing UI
- existing components
- existing state management
- existing routing
- existing API clients
- existing environment variables
- tests
- build configuration
- documentation

Also inspect:

- AGENTS.md files
- installed skills
- package manifests
- README files
- configuration files

Never overwrite working functionality blindly.

Preserve useful existing code when appropriate.

---

# 7. CREATE A PROJECT AUDIT

Before major implementation, create:

docs/project-audit.md

Include:

## Current Architecture

## Existing Features

## Existing UI Architecture

## Existing Reusable Components

## Existing Design Tokens

## Existing Technical Debt

## Missing Features

## Security Risks

## Accessibility Problems

## Performance Risks

## Recommended Refactoring

## Implementation Roadmap

Do not modify major application architecture before understanding what already exists.

---

# 8. TARGET ARCHITECTURE

Preferred architecture:

Flutter Mobile
+
ASP.NET Core Web API
+
PostgreSQL
+
PostGIS
+
Redis
+
SignalR
+
Background Workers
+
Google APIs
+
FCM / APNs

Backend architecture:

Modular Monolith.

Do NOT introduce microservices unless there is a clear engineering reason.

Suggested backend structure:

backend/

    CoupleApp.API/
    CoupleApp.Application/
    CoupleApp.Domain/
    CoupleApp.Infrastructure/

    Modules/
        Auth/
        Couples/
        Cycles/
        Tasks/
        Calendar/
        Google/
        Location/
        Memories/
        Expenses/
        Shopping/
        Notifications/
        CheckIns/

workers/

    CoupleApp.SyncWorker/

Frontend structure:

mobile/

    lib/
        core/
            network/
            storage/
            theme/
            routing/
            widgets/
            utils/

        features/
            auth/
            couple/
            home/
            cycle/
            tasks/
            calendar/
            location/
            memories/
            expenses/
            shopping/
            anniversaries/
            checkins/
            settings/

Use feature-oriented architecture.

---

# 9. DOMAIN MODEL

Core domain:

User
Couple
CoupleMember

Health:

CycleProfile
PeriodEntry
CyclePrediction

Productivity:

Task
CalendarEvent
ShoppingList
ShoppingItem

Location:

LocationSettings
LocationSharingSession
LocationPoint
Place
Geofence

Memories:

Memory
MemoryAlbum

Finance:

Expense
ExpenseParticipant

Relationship:

Anniversary
ImportantDate
CheckIn

Integrations:

GoogleConnection
GoogleCalendarMapping
GoogleTaskMapping

Notifications:

Notification
Device
PushSubscription

---

# 10. COUPLE MODEL

Couple is the central shared workspace.

A Couple has exactly two active members.

Do not hard-code product logic around gender combinations.

Instead:

User

    cycleTrackingEnabled
    locationSharingEnabled
    ...

This allows:

Male + Female:
    one or both may enable cycle tracking

Female + Female:
    both may enable cycle tracking

Male + Male:
    normally no cycle tracking

The application should not assume a person's health settings from gender alone.

---

# 11. MENSTRUAL CYCLE TRACKING

Implement cycle tracking as a private, permission-controlled feature.

Entities:

CycleProfile

    UserId
    AverageCycleLength
    AveragePeriodLength
    TrackingEnabled
    Visibility
    CreatedAt
    UpdatedAt

PeriodEntry

    CycleProfileId
    StartDate
    EndDate
    FlowLevel
    PainLevel
    Notes
    CreatedAt
    UpdatedAt

Prediction

    ExpectedStart
    EarliestStart
    LatestStart
    Confidence
    GeneratedAt

The system must treat predictions as estimates.

Do not present cycle prediction as medical advice.

Do not present prediction as contraception.

---

# 12. CYCLE PREDICTION

Initial implementation should be deterministic and understandable.

Use historical cycle intervals.

Example:

28
29
29
28

Calculate a sensible personalized estimate.

Do not introduce machine learning unless it is justified by real data and validated properly.

Architect the prediction system so the algorithm can later evolve:

Version 1:

Simple average / weighted average

Future possibilities:

Moving average
Weighted moving average
Bayesian model
Personalized probabilistic model

Store prediction history so prediction accuracy can later be evaluated.

Track:

PredictedDate
ActualDate
PredictionError

---

# 13. PRIVACY FOR CYCLE DATA

Cycle information is personal data.

Every user must control whether their partner can view it.

Possible values:

PRIVATE
PARTNER

The backend must authorize every request.

Never trust the Flutter client to enforce privacy.

Authorization must be verified server-side.

---

# 14. SHARED TASKS

Implement:

- personal tasks
- partner tasks
- shared tasks
- assignment
- due date
- priority
- completion
- overdue state
- task filtering
- task sorting
- optimistic UI where appropriate

Task entity:

Task

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

Source:

INTERNAL
GOOGLE_TASKS

---

# 15. CALENDAR

Implement an internal Couple Calendar first.

Calendar supports:

- shared events
- personal events where appropriate
- date
- time
- duration
- title
- description
- location
- recurring event support where appropriate
- event reminders

Do not make Google Calendar the application's primary database.

Couple App owns its internal shared data.

External services are integrations.

---

# 16. GOOGLE CALENDAR

Implement OAuth securely.

Store connection information separately from business data.

Concept:

GoogleConnection

    UserId
    Provider
    GoogleAccountId
    EncryptedAccessToken
    EncryptedRefreshToken
    TokenExpiresAt
    Status

Implement synchronization using an appropriate incremental synchronization strategy.

Maintain mapping between:

Couple App Event
and
Google Event

Do not duplicate events unnecessarily.

Handle:

- create
- update
- delete
- external changes
- token expiration
- authorization revocation
- sync failure
- retry

Synchronization should occur in a worker/background process where appropriate.

---

# 17. GOOGLE TASKS

Use the same architectural principle.

Couple App owns its core task model.

Google Tasks is an integration.

Implement:

- account connection
- task mapping
- synchronization
- external updates
- completed state
- deleted state
- conflict handling
- retry

Do not tightly couple application domain logic to the Google API schema.

---

# 18. REALTIME

Use SignalR for realtime Couple interactions.

Potential realtime events:

TaskUpdated
TaskCompleted
CalendarEventUpdated
LocationUpdated
CheckInUpdated
NotificationCreated

A partner should see relevant shared changes without manually refreshing.

Do not use realtime where it is unnecessary.

---

# 19. LOCATION SYSTEM

Location is a privacy-sensitive feature.

Support:

OFF
LAST_SEEN
LIVE
LIVE_FOR_15_MIN
LIVE_FOR_1_HOUR

Each user controls whether location sharing is enabled.

Never silently track the user.

UI must clearly communicate active location sharing.

Always provide an obvious:

STOP SHARING

action.

---

# 20. LOCATION DATA

Do not send GPS updates every second.

Use adaptive update strategies.

Consider:

- movement
- distance
- time
- battery
- app state

Store geographic data using PostGIS where appropriate.

LocationPoint:

    SessionId
    Latitude
    Longitude
    Accuracy
    Speed
    Heading
    RecordedAt

Location history must have configurable retention.

Example:

24 hours
7 days
30 days
disabled

---

# 21. PLACES AND GEOFENCING

Support user-created places such as:

Home
University
Work
Gym
Favorite locations

Support:

arrival notification
departure notification

Example:

Partner enters the configured Home geofence.

Generate:

"Partner arrived home."

Do not infer or generate private conclusions from location data.

---

# 22. MEMORIES

Implement:

- photo memories
- captions
- dates
- locations
- albums
- timeline
- monthly/yearly summaries

Use object storage for images.

Do not store large binary files directly in relational database records unless there is a clear reason.

---

# 23. SHARED EXPENSES

Implement:

Expense

    CoupleId
    PaidByUserId
    Amount
    Currency
    Category
    Description
    Date

Support:

- equal split
- custom split
- expense history
- balances
- settlement tracking

The UI must make calculations understandable.

Avoid financial complexity in the first MVP.

---

# 24. SHOPPING LIST

Implement collaborative shopping lists.

Features:

- add item
- remove item
- quantity
- category
- completed state
- partner updates in realtime

Keep interaction fast and frictionless.

---

# 25. ANNIVERSARIES AND IMPORTANT DATES

Support:

Relationship anniversary
Birthday
First meeting
First date
Custom important date

Display:

days together
countdown
upcoming important dates

---

# 26. COUPLE CHECK-IN

Implement a lightweight shared status system.

Examples:

Good
Normal
Tired
Busy
On the way
At home

Do not implement Couple Chat.

Do not implement Care Mode.

---

# 27. HOME SCREEN

Home is the central dashboard.

It should intelligently summarize the current state.

Potential sections:

Couple header
Days together
Today's events
Today's tasks
Task progress
Partner location
Cycle information when enabled
Upcoming important date
Quick actions
Recent memories
Expense summary

Do not overload the screen.

Prioritize what is useful today.

---

# 28. FLUTTER UI PRINCIPLES

Use Material 3 and/or Cupertino appropriately.

Build adaptive layouts.

Support:

Android
iOS
small screens
large phones
dynamic text size
dark mode

Do not blindly use default Flutter Material styling.

Create a coherent product identity.

---

# 29. DESIGN TOKENS

Create centralized tokens for:

Colors
Typography
Spacing
Radii
Elevation
Motion
Icon sizing
Touch targets

Do not scatter magic numbers across widgets.

Bad:

Color(0xFF...)
Padding(17)
BorderRadius.circular(13)

unless there is a deliberate documented exception.

Prefer:

AppColors.primary
AppSpacing.md
AppRadius.card
AppTypography.titleMedium

---

# 30. COMPONENT ARCHITECTURE

Create reusable components only when reuse is justified.

Do not build a giant generic component system.

Components should have clearly defined:

Anatomy
Properties
Variants
States
Behavior
Accessibility
Tokens

Before creating a reusable component, check whether one already exists.

---

# 31. REQUIRED COMPONENTS

Build reusable foundations such as:

AppButton
AppIconButton
AppTextField
AppCard
AppAvatar
AppChip
AppBottomSheet
AppDialog
AppEmptyState
AppErrorState
AppLoadingState
AppSectionHeader

Product components:

TaskCard
EventCard
CycleCard
PredictionCard
LocationCard
PlaceCard
MemoryCard
ExpenseCard
ShoppingItem
AnniversaryCard
CheckInCard

Do not create all components at once.

Create them when needed by screens.

---

# 32. REQUIRED UI STATES

Every important screen and component must consider:

Loading
Empty
Error
Success
Disabled
Selected
Pressed
Completed
Offline
Permission denied
Unauthorized
Syncing
Sync failed

For network-driven screens:

Loading
Error
Retry
Empty

must not be forgotten.

---

# 33. ACCESSIBILITY

Review all important screens for:

Semantic labels
Screen reader behavior
Contrast
Touch target size
Text scaling
Focus order
Keyboard accessibility where relevant
Reduced motion
Color independence

Do not encode meaning using color alone.

---

# 34. NAVIGATION

Use a coherent mobile navigation structure.

Suggested main destinations:

Home
Calendar
Tasks
Location
More

Inside More:

Cycle
Memories
Expenses
Shopping
Anniversaries
Check-ins
Settings

However, do not blindly implement this if repository analysis suggests a better structure.

The primary navigation should prioritize actual user frequency.

---

# 35. STATE MANAGEMENT

Choose a modern, maintainable Flutter state management solution.

Prefer a solution that provides:

- clear dependency boundaries
- testability
- predictable state flow
- asynchronous state handling
- minimal boilerplate

Do not introduce multiple state management frameworks.

Use one primary approach consistently.

---

# 36. NETWORKING

Create a centralized API client.

Requirements:

- base URL configuration
- auth headers
- token refresh
- retries where appropriate
- error normalization
- request logging in development
- no sensitive information in production logs

Use typed API models.

Do not scatter raw HTTP calls across UI widgets.

---

# 37. ERROR HANDLING

Build a consistent error model.

Differentiate:

Validation errors
Authentication errors
Authorization errors
Not found
Conflict
Rate limiting
Server errors
Network failures
Offline state
Integration errors

The UI should show useful human-readable messages.

Do not expose stack traces or internal server details.

---

# 38. SECURITY

Security is a first-class requirement.

Implement:

HTTPS
secure authentication
password hashing
JWT access tokens
refresh tokens
token rotation where appropriate
authorization checks
rate limiting
input validation
SQL injection protection
secure storage
encrypted OAuth tokens
audit logging where appropriate

Never trust IDs supplied by the client.

Always verify:

User → Couple membership → Resource ownership/access

---

# 39. DATABASE

Use PostgreSQL.

Use Entity Framework Core.

Design normalized tables where appropriate.

Use migrations.

Do not store secrets in source code.

Use:

.env

or secure environment configuration.

Never commit:

API keys
OAuth client secrets
refresh tokens
database passwords
private keys

---

# 40. REDIS

Use Redis only where beneficial.

Potential uses:

Caching
short-lived sessions
distributed SignalR support if later needed
rate limiting
temporary synchronization state

Do not introduce Redis complexity unnecessarily for data that belongs in PostgreSQL.

---

# 41. BACKGROUND JOBS

Use a Worker Service / Hangfire-style architecture for:

Google synchronization
notification processing
cleanup
prediction generation
location history retention
scheduled reminders

Controllers should remain lightweight.

---

# 42. NOTIFICATIONS

Support:

Task reminders
Calendar reminders
Cycle prediction reminders
Partner location events
Arrival/departure alerts
Important date reminders
Sync issues where useful

Separate notification creation from notification delivery.

Use appropriate mobile push infrastructure.

---

# 43. OFFLINE-FIRST THINKING

Important user interactions should degrade gracefully when connectivity is temporarily unavailable.

Especially:

Tasks
Shopping List
Check-in

Use appropriate local caching.

Do not pretend an operation succeeded if synchronization has actually failed.

Use clear sync indicators.

---

# 44. TESTING

Implement tests continuously.

Backend:

Unit tests
Integration tests
Authorization tests
Domain tests

Flutter:

Widget tests
Unit tests
Navigation tests for critical flows

Important scenarios:

registration
login
couple invite
couple join
task creation
task completion
cycle entry
cycle prediction
privacy access
location permission
location sharing
Google authorization
sync failures

---

# 45. UI QUALITY ASSURANCE

Before marking any screen complete, review:

1. Visual hierarchy
2. Spacing consistency
3. Typography
4. Component reuse
5. Design token usage
6. States
7. Interaction
8. Accessibility
9. Responsive behavior
10. Loading behavior
11. Empty state
12. Error state
13. Performance
14. Dark mode
15. Overall product consistency

Use:

.agents/skills/couple-design-system/references/ui-review-checklist.md

---

# 46. VISUAL REVIEW

When screenshots or running UI are available:

Inspect them critically.

Do not assume the implementation is correct simply because the code compiles.

Look for:

- excessive cards
- repetitive rounded rectangles
- poor hierarchy
- generic layouts
- excessive whitespace
- cramped spacing
- inconsistent radii
- inconsistent typography
- random colors
- weak CTA hierarchy
- unnecessary decoration
- poor navigation
- confusing states

Use Taste Skill to improve visual quality.

Use Couple Design System to preserve consistency.

Do not sacrifice usability for visual novelty.

---

# 47. PERFORMANCE

Flutter performance requirements:

Avoid unnecessary rebuilds
Avoid expensive work in build()
Use lazy lists where needed
Optimize images
Avoid excessive animations
Avoid uncontrolled realtime streams
Respect battery usage
Be careful with location updates

Backend:

Use pagination
Use indexes
Avoid N+1 queries
Use caching selectively
Use asynchronous I/O
Use background jobs for long operations

---

# 48. DEVELOPMENT PHASES

Implement the application incrementally.

PHASE 0 — AUDIT

- inspect repository
- inspect skills
- inspect existing project
- produce docs/project-audit.md
- produce implementation roadmap

PHASE 1 — FOUNDATION

- Flutter architecture
- ASP.NET Core architecture
- PostgreSQL
- migrations
- authentication
- configuration
- API client
- routing
- design tokens
- theme
- base components

PHASE 2 — COUPLE

- create couple
- invite partner
- join couple
- couple membership
- couple home
- permissions

PHASE 3 — TASKS

- task CRUD
- assignment
- completion
- filtering
- realtime updates

PHASE 4 — CALENDAR

- internal calendar
- shared events
- reminders

PHASE 5 — CYCLE

- cycle profile
- period logging
- calendar
- prediction
- privacy

PHASE 6 — GOOGLE INTEGRATIONS

- Google OAuth
- Calendar sync
- Tasks sync
- mapping
- worker architecture
- error handling

PHASE 7 — LOCATION

- permissions
- sharing sessions
- last seen
- live location
- PostGIS
- realtime updates
- history
- places
- geofence
- arrival/departure events

PHASE 8 — MEMORIES

- albums
- photos
- captions
- timeline

PHASE 9 — EXPENSES

- expenses
- splitting
- balances

PHASE 10 — SHOPPING

- collaborative shopping lists
- realtime updates

PHASE 11 — ANNIVERSARIES / CHECK-INS

- important dates
- countdown
- check-in status

PHASE 12 — HARDENING

- security
- accessibility
- performance
- testing
- error handling
- offline behavior
- privacy review

PHASE 13 — RELEASE PREPARATION

- production configuration
- Docker
- deployment configuration
- CI/CD
- logging
- monitoring
- documentation

---

# 49. IMPORTANT IMPLEMENTATION RULE

Do not implement the entire roadmap in one uncontrolled pass.

Work phase-by-phase.

At the beginning of each phase:

1. Read relevant requirements.
2. Inspect current implementation.
3. Identify reusable code.
4. Define changes.
5. Implement.
6. Test.
7. Review.
8. Refactor if needed.
9. Update documentation.

Then proceed to the next phase.

---

# 50. DO NOT ASK UNNECESSARY QUESTIONS

When requirements are clear, make a reasonable engineering decision and proceed.

If there are multiple technically valid approaches, choose the simplest maintainable approach consistent with this architecture.

Record major architectural decisions in:

docs/architecture-decisions.md

Do not stop implementation merely because a non-critical choice is unspecified.

---

# 51. DOCUMENTATION

Maintain:

docs/

    project-audit.md
    architecture.md
    architecture-decisions.md
    database.md
    api.md
    security.md
    design-system.md
    deployment.md

Update documentation when architecture changes.

---

# 52. GIT DISCIPLINE

Do not delete working functionality without justification.

Keep changes logically grouped.

Prefer small meaningful commits when git workflow is available.

Commit examples:

feat(auth): implement authentication
feat(couple): add couple invitations
feat(tasks): add shared tasks
feat(cycle): add period tracking
feat(calendar): add shared calendar
feat(location): add location sharing

Do not commit secrets.

---

# 53. DEFINITION OF DONE

A feature is NOT complete simply because it compiles.

A feature is complete when:

- implementation works
- architecture is clean
- UI is consistent
- states are handled
- errors are handled
- permissions are handled
- accessibility is considered
- tests exist where appropriate
- documentation is updated
- security has been considered
- performance is acceptable

---

# 54. FIRST TASK

Start NOW.

Do not implement feature code immediately.

First:

1. Inspect the repository recursively.
2. Inspect AGENTS.md files.
3. Inspect installed skills relevant to this project.
4. Identify the current Flutter project.
5. Identify the current backend if any.
6. Identify database configuration.
7. Identify existing UI.
8. Identify existing reusable components.
9. Run appropriate project checks.
10. Produce:

docs/project-audit.md

11. Produce:

docs/implementation-plan.md

12. Produce:

docs/architecture.md

13. Produce:

docs/design-system.md

14. Summarize the current state.

Then begin PHASE 1.

IMPORTANT:

Do not redesign the UI blindly.

Do not generate random screens.

Do not create a new visual language for every screen.

Build the Couple App as one coherent product.

Use the Couple Design System as the source of truth.

Use Nathan Curtis / EightShapes methodology for system thinking.

Use Taste Skill for visual quality.

Use Flutter AI UI Skill for Flutter-specific UI/UX implementation.

The final result should feel like a professionally designed and engineered mobile product, not an AI-generated demo.