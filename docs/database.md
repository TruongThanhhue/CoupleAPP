# Database plan

PostgreSQL is the system of record; PostGIS is planned with the Location module. The current development schema uses EF Core creation plus an additive SQL upgrade; a versioned production migration strategy is still required.

## Implemented tables

- `users`: email, salted password hash, public partner code, and an optional reciprocal partner reference.
- `partner_invites`: sender, recipient, timestamps, and invitation status.
- `workspace_tasks`: owner, explicit sharing recipient, title/notes, completion, priority and optional due date.
- `calendar_events`: owner, explicit sharing recipient, title/notes/location and start/end timestamps.

In Development, the API creates these tables on first startup with EF Core `EnsureCreated`, then applies the idempotent additive script `backend/CoupleApp.API/Data/Migrations/001_workspace.sql`. This also adds the two new tables to databases that already contain accounts; it does not drop existing data. The script is embedded in the API build.

For an existing production database with the account schema, review and apply the script in a transaction before deploying this API version. Do not delete the database to add the new features. This script is an incremental development upgrade, not a complete baseline/history for production deployment.

## Planned core tables

- `user_settings`, `devices`
- `couples`, `couple_members`
- `event_participants`, task assignment and reminder metadata
- `cycle_profiles`, `period_entries`, `cycle_predictions`

Later feature tables include location sessions/points/places, memories/albums, expenses/participants, shopping lists/items, important dates, check-ins, notifications, and provider mappings.

## Data handling

Current tasks/events use an owner and optional `SharedWithUserId`. Server queries verify mutual partner membership before granting the recorded recipient access. A changed partner does not gain access to earlier shared data. The owner always retains access; only the owner can change sharing. Personal records have no recipient.

Planned health and integration records require owner/visibility authorization. OAuth encryption and location retention will be implemented with their respective modules; neither feature is present yet.
