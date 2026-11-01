# API plan

The API is versioned under `/api/v1`. Controllers or minimal route groups must translate HTTP only; authorization-aware application services own use cases.

## Foundation endpoint

`GET /health` reports process health. `GET /api/v1/home` requires a bearer token and returns visible task totals and upcoming events from the database. The Flutter home also derives its summary from the shared workspace controller so saved changes are reflected across tabs.

## Implemented authentication and partner endpoints

- `POST /api/v1/auth/register`: create an account, issue an access token, and return a personal `CPL-XXXXXXXX` code.
- `POST /api/v1/auth/login`: sign in with email and password.
- `GET /api/v1/couples/me`: current profile and connected partner, if any.
- `GET /api/v1/couples/invites`: incoming pending invitations.
- `GET /api/v1/couples/invites/sent`: outgoing pending invitations.
- `POST /api/v1/couples/invites`: send an invitation using the recipient's public code.
- `POST /api/v1/couples/invites/{id}/accept`: accept an incoming invitation and link both accounts.
- `POST /api/v1/couples/invites/{id}/decline`: decline an incoming invitation.
- `POST /api/v1/couples/invites/{id}/cancel`: withdraw an outgoing invitation.

All `/couples` endpoints require a bearer token. The public code is for invitations only; it does not authorize access to private data.

## Implemented tasks and events

All routes require a bearer token:

| Resource | List / create | Update / delete |
| --- | --- | --- |
| Tasks | `GET /tasks`, `POST /tasks` | `PUT /tasks/{id}`, `DELETE /tasks/{id}` |
| Calendar events | `GET /events`, `POST /events` | `PUT /events/{id}`, `DELETE /events/{id}` |

Routes above are relative to `/api/v1`. Task write bodies contain `title`,
`notes`, `isComplete`, `isShared`, `priority` (`low`, `normal`, `high`) and
nullable `dueAt`. Event write bodies contain `title`, `notes`, `location`,
`startsAt`, `endsAt` and `isShared`. Dates use ISO 8601 UTC; the client displays
local time. Responses additionally contain `id`, `createdAt`, `updatedAt` and
`createdByMe`.

Records default to private in the app. Shared records capture the connected
partner at sharing time; access requires that the two users are still mutually
connected. A future partner does not automatically inherit old records. Both
members may edit/delete shared records, but only the creator may change sharing.
Unknown or inaccessible record IDs return 404. Personal records are never
included in the other person's list or dashboard.

## Planned core endpoints

- `/auth`: refresh, server-side logout, Google OAuth.
- `/couples`: dedicated workspace model and leave operation.
- `/tasks`: assignment, realtime delivery, pagination and conflict resolution.
- `/events`: reminders, recurrence and external calendar integrations.
- `/cycles`: manage profile, period entries, and private/partner-visible prediction reads.

Responses use RFC 9457 problem details for failures. Error messages are user-safe and do not expose stack traces or sensitive payloads.
