# Architecture

## Context

Couple App is a private shared workspace for exactly two active couple members. Its data falls into three access categories:

- **Private:** individual cycle records, personal notes, raw location history, OAuth data.
- **Couple:** tasks, events, memories, expenses, shopping lists, important dates, and voluntary check-ins.
- **Integration:** provider mappings, synchronization cursors, and encrypted provider tokens.

## System shape

```text
Flutter mobile client
        |
 HTTPS REST + SignalR (where real-time value exists)
        |
ASP.NET Core modular monolith
  API | Application | Domain | Infrastructure
        |
 PostgreSQL + PostGIS
        |
 Worker processes for sync, reminders, cleanup, and prediction jobs
```

Redis, object storage, push delivery, Google APIs, and maps are optional infrastructure dependencies introduced only by their owning feature.

## Backend boundaries

`CoupleApp.Domain` owns entities, value objects, and invariants. `CoupleApp.Application` owns use cases, authorization-aware commands/queries, and interfaces. `CoupleApp.Infrastructure` owns EF Core, external providers, token encryption, and persistence. `CoupleApp.API` owns HTTP/SingalR transport, authentication middleware, and dependency composition.

Feature modules own their domain language: Auth, Couples, Tasks, Calendar, Cycles, Google, Location, Memories, Expenses, Shopping, Anniversaries, CheckIns, and Notifications. Modules remain in one deployable monolith until a concrete scaling need warrants separation.

## Authorization model

Every request resolves the authenticated user, then validates membership and resource ownership. A user-supplied couple or resource ID is never authority. Cycle visibility and location-sharing consent are checked on the server for every relevant read/write operation. A couple must have no more than two active members.

## Mobile architecture

The Flutter client is feature-oriented. `core/` contains theme tokens, routing, API and storage abstractions, shared widgets, and utilities. Each feature owns its presentation, state, models, and repository interface. UI widgets do not issue raw HTTP requests and cannot be the source of a privacy decision.

Use one asynchronous state-management approach consistently (Riverpod is the proposed choice). Routing is declarative. Server models are mapped at the data boundary instead of being used directly throughout screens.

## Integration and asynchronous work

The internal database remains the source of truth for tasks and events. Google services are adapter-backed integrations with encrypted tokens, mappings, retry behavior, conflict policy, and synchronization state. Long-running or scheduled work is processed outside request handlers. SignalR communicates shared changes only; it does not replace normal persistence.

## Security baseline

- HTTPS, short-lived access tokens, refresh-token rotation, password hashing, rate limiting, input validation, audit events, and secure mobile token storage.
- Configuration through environment variables or a secret store. Checked-in files contain placeholders only.
- OAuth tokens encrypted at rest; logs redact tokens, credentials, and sensitive health/location payloads.
- Location sharing is off by default, visibly active when enabled, time-limited when requested, and has an obvious stop control.
