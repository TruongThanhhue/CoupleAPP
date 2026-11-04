CREATE TABLE IF NOT EXISTS shared_entries (
    "Id" uuid PRIMARY KEY, "OwnerId" uuid NOT NULL REFERENCES users("Id"),
    "RecipientId" uuid REFERENCES users("Id"), "Kind" text NOT NULL,
    "Title" text NOT NULL, "Day" date NOT NULL, "Detail" text,
    "Amount" bigint, "PayerId" uuid REFERENCES users("Id"), "Done" boolean NOT NULL
);
CREATE INDEX IF NOT EXISTS shared_entries_pair_month ON shared_entries ("OwnerId","RecipientId","Kind","Day");
