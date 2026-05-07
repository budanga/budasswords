-- Supabase migration: 001_initial_schema.sql
-- Run via: supabase db push

CREATE TABLE IF NOT EXISTS vault_entries (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title_enc    BYTEA       NOT NULL,
  url_enc      BYTEA,
  content_enc  BYTEA       NOT NULL,
  iv           BYTEA       NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at   TIMESTAMPTZ,
  server_rev   BIGINT      NOT NULL DEFAULT 1
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_vault_entries_user_id
  ON vault_entries (user_id);

CREATE INDEX IF NOT EXISTS idx_vault_entries_updated_at
  ON vault_entries (updated_at DESC);

-- Row-Level Security
ALTER TABLE vault_entries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users own their entries" ON vault_entries;
CREATE POLICY "Users own their entries"
  ON vault_entries
  FOR ALL
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Auto-update updated_at and bump server_rev on every UPDATE
CREATE OR REPLACE FUNCTION bump_vault_entry_revision()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  NEW.server_rev = OLD.server_rev + 1;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS vault_entry_revision_trigger ON vault_entries;
CREATE TRIGGER vault_entry_revision_trigger
  BEFORE UPDATE ON vault_entries
  FOR EACH ROW
  EXECUTE FUNCTION bump_vault_entry_revision();
