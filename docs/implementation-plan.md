# Implementation plan

## Scope and sequencing

The product will be developed as a phased privacy-first mobile application. This plan deliberately does not treat every module in the specification as an immediate implementation target.

### Phase 1 — Foundation

- Scaffold `mobile/couple_app` using Flutter Material 3 and feature-oriented folders.
- Scaffold the ASP.NET Core modular monolith under `backend/`.
- Establish semantic light/dark theme tokens, routing, application shell, state-management convention, API client boundary, error model, and baseline components.
- Add `.env.example` files only; never put keys or credentials in source.
- Establish tests and a local-development configuration.

### Phase 2 — Couple workspace

- Authentication and secure session flow.
- Create, invite, join, and leave-couple operations.
- Couple membership authorization policy.
- A dashboard which summarizes only data useful today.

### Phase 3 — Tasks

- Shared/personal task model, assignment, completion, priority, due state, filters, and optimistic UI.
- Unit and authorization tests before realtime delivery.

### Phase 4 — Calendar

- Internal shared events, reminders, and event presentation.

### Phase 5 — Cycle

- Opt-in tracking profile, period entries, deterministic prediction, visible estimate language, and server-enforced visibility.

### Later phases

Google integrations, SignalR delivery, location, memories, expenses, shopping, anniversaries, check-ins, notifications, offline behavior, and deployment follow in the master prompt's stated order.

## Phase 1 delivery criteria

- A runnable Flutter shell uses the Couple theme, adaptive navigation, and explicit loading/empty/error patterns.
- A server solution has explicit API, Application, Domain, and Infrastructure boundaries.
- The system has no embedded secrets.
- UI foundations have tokens, documented states, and accessibility expectations.
- Formatting, static analysis, and focused tests pass once Flutter is installed.

## Current execution note

As of November 2026, Flutter/Dart and .NET are installed. Authentication and partner
invitations have API/client implementations. Tasks and calendar events now have
PostgreSQL-backed CRUD and explicit private/shared visibility. Home uses the
signed-in user's real workspace. Task assignment, optimistic conflict handling,
calendar reminders/recurrence, couple unlinking, cycle tracking and later
integrations remain to be implemented. Local verification outcomes are recorded
in `docs/workspace-verification.md`; production release criteria remain open.
