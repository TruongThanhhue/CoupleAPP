-- Existing rows start at a baseline version; every later write rotates it.
ALTER TABLE workspace_tasks ADD COLUMN IF NOT EXISTS "Version" uuid NOT NULL
    DEFAULT '00000000-0000-0000-0000-000000000000';
ALTER TABLE workspace_tasks ADD COLUMN IF NOT EXISTS "AssignedToUserId" uuid NULL
    REFERENCES users ("Id") ON DELETE RESTRICT;
CREATE INDEX IF NOT EXISTS "IX_workspace_tasks_AssignedToUserId" ON workspace_tasks ("AssignedToUserId");
ALTER TABLE calendar_events ADD COLUMN IF NOT EXISTS "Version" uuid NOT NULL
    DEFAULT '00000000-0000-0000-0000-000000000000';
