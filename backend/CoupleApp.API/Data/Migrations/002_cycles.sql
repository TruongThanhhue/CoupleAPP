-- Additive, repeatable upgrade for existing account/workspace databases.
CREATE TABLE IF NOT EXISTS cycle_profiles (
    "UserId" uuid PRIMARY KEY REFERENCES users ("Id") ON DELETE RESTRICT,
    "TrackingEnabled" boolean NOT NULL,
    "Visibility" integer NOT NULL,
    "SharedWithUserId" uuid NULL REFERENCES users ("Id") ON DELETE RESTRICT,
    "AverageCycleLength" integer NOT NULL,
    "AveragePeriodLength" integer NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL
);
CREATE INDEX IF NOT EXISTS "IX_cycle_profiles_SharedWithUserId" ON cycle_profiles ("SharedWithUserId");
CREATE TABLE IF NOT EXISTS period_entries (
    "Id" uuid PRIMARY KEY,
    "UserId" uuid NOT NULL REFERENCES cycle_profiles ("UserId") ON DELETE RESTRICT,
    "StartDate" date NOT NULL,
    "EndDate" date NULL,
    "FlowLevel" character varying(16) NOT NULL,
    "PainLevel" integer NULL,
    "Notes" character varying(2000) NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAt" timestamp with time zone NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS "IX_period_entries_UserId_StartDate" ON period_entries ("UserId", "StartDate");
CREATE TABLE IF NOT EXISTS cycle_predictions (
    "Id" uuid PRIMARY KEY,
    "UserId" uuid NOT NULL REFERENCES cycle_profiles ("UserId") ON DELETE RESTRICT,
    "AnchorStart" date NOT NULL,
    "ExpectedStart" date NOT NULL,
    "EarliestStart" date NOT NULL,
    "LatestStart" date NOT NULL,
    "Basis" character varying(16) NOT NULL,
    "IntervalCount" integer NOT NULL,
    "AlgorithmVersion" character varying(40) NOT NULL,
    "GeneratedAt" timestamp with time zone NOT NULL,
    "ActualStart" date NULL,
    "ErrorDays" integer NULL
);
CREATE INDEX IF NOT EXISTS "IX_cycle_predictions_UserId_GeneratedAt" ON cycle_predictions ("UserId", "GeneratedAt");
