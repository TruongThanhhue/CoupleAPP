-- Additive and repeatable upgrade for existing users/partner_invites databases.
-- No existing tables or rows are deleted. For production, run inside a transaction.
CREATE TABLE IF NOT EXISTS workspace_tasks (
    "Id" uuid PRIMARY KEY,
    "OwnerId" uuid NOT NULL REFERENCES users ("Id") ON DELETE RESTRICT,
    "SharedWithUserId" uuid NULL REFERENCES users ("Id") ON DELETE RESTRICT,
    "Title" character varying(200) NOT NULL,
    "Notes" character varying(2000) NULL,
    "IsComplete" boolean NOT NULL,
    "Priority" character varying(10) NOT NULL,
    "DueAt" timestamp with time zone NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL
);
CREATE INDEX IF NOT EXISTS "IX_workspace_tasks_OwnerId" ON workspace_tasks ("OwnerId");
CREATE INDEX IF NOT EXISTS "IX_workspace_tasks_SharedWithUserId" ON workspace_tasks ("SharedWithUserId");

CREATE TABLE IF NOT EXISTS calendar_events (
    "Id" uuid PRIMARY KEY,
    "OwnerId" uuid NOT NULL REFERENCES users ("Id") ON DELETE RESTRICT,
    "SharedWithUserId" uuid NULL REFERENCES users ("Id") ON DELETE RESTRICT,
    "Title" character varying(200) NOT NULL,
    "Notes" character varying(2000) NULL,
    "Location" character varying(300) NULL,
    "StartsAt" timestamp with time zone NOT NULL,
    "EndsAt" timestamp with time zone NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL
);
CREATE INDEX IF NOT EXISTS "IX_calendar_events_OwnerId" ON calendar_events ("OwnerId");
CREATE INDEX IF NOT EXISTS "IX_calendar_events_SharedWithUserId" ON calendar_events ("SharedWithUserId");
