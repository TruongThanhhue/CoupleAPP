# Project audit

_Updated: 01 November 2026. Describes implementation; see workspace-verification.md for executed checks._

## Current implementation

- Flutter Android project with semantic light/dark tokens and navigation.
- ASP.NET Core API with PostgreSQL, password hashing, JWT and rate limits on
  authentication/invitations.
- Email registration/login, public partner code, invitation acceptance/decline/
  cancellation and client sign out.
- Persistent tasks: create/edit/delete, completion, priority, due dates and
  completion filters.
- Persistent calendar agenda: create/edit/delete, start/end time, location and
  upcoming/all filters.
- Per-record private/shared visibility, enforced on the server. Only the creator
  changes sharing; shared access is bound to the recorded, current mutual partner.
- Home reads the signed-in workspace, with task counts and today's events; no
  invented relationship duration or sample couple identity.

## Architecture and schema

The API has API/Application/Domain/Infrastructure projects, although much current
orchestration still lives in API endpoints. Domain Couple/CoupleMember is not yet
the persisted membership model; accounts use reciprocal PartnerId references.
Workspace tables use owner/recipient identities to enforce visibility.

Development schema creation uses EnsureCreated plus an additive repeatable SQL
upgrade for workspace tables. This preserves existing account data but is not a
complete production schema migration lifecycle.

## Remaining product work

- Task assignment and conflict handling across devices.
- Calendar reminders, recurrence, and external calendar sync.
- Partner unlinking, relationship date/profile editing.
- Password recovery, email verification, token refresh/revocation and account deletion.
- Cycle tracking/privacy, location, memories, expenses, shopping, anniversaries,
  check-ins, notifications and offline synchronization.

## Release gaps

CI/CD, versioned production migrations, production configuration, operational
monitoring/backups, security review, broader multi-device tests and store release
configuration are still required. iOS platform scaffolding is not present.
Android still uses the generated application identity/icons.

## UI and behavior

Tasks/calendar/home reuse AppSurfaceCard, AppStatePanel, AppSectionHeader,
AppSpace and theme colors/typography. Loading, empty, retry, saving, error,
completed and sharing states are explicit. Records refresh on tab switching,
app resume and manual refresh; there is no realtime push synchronization yet.

No overall completion percentage is mechanically measured. Assess progress by
working and verified capabilities against a defined release scope.
