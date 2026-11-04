-- Existing entries receive the same baseline used by versioned workspace records.
ALTER TABLE period_entries ADD COLUMN IF NOT EXISTS "Version" uuid NOT NULL
    DEFAULT '00000000-0000-0000-0000-000000000000';

-- Older clients could correct or delete a period while leaving predictions
-- anchored to its former date. Preserve the history of existing periods.
DELETE FROM cycle_predictions AS prediction
WHERE NOT EXISTS (
    SELECT 1 FROM period_entries AS period
    WHERE period."UserId" = prediction."UserId" AND period."StartDate" = prediction."AnchorStart"
);
