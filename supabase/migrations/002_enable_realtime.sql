-- Enable Realtime for the vault_entries table
BEGIN;
  -- Remove the table from the publication if it exists (to prevent duplicates)
  ALTER PUBLICATION supabase_realtime DROP TABLE vault_entries;
EXCEPTION
  WHEN undefined_object THEN null;
END;

ALTER PUBLICATION supabase_realtime ADD TABLE vault_entries;
