DO $$
BEGIN
  CREATE TYPE hq_catalog.host_sync_state AS ENUM (
    'idle',
    'interrupted',
    'needs_review'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS hq_catalog.host_devices (
  host_device_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  display_name text NOT NULL,
  venue_label text,
  app_version text,
  local_free_space_bytes bigint,
  local_library_root text,
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  is_active boolean NOT NULL DEFAULT true,
  sync_state hq_catalog.host_sync_state NOT NULL DEFAULT 'idle',
  interrupted_sync_state jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT host_devices_display_name_not_blank CHECK (btrim(display_name) <> ''),
  CONSTRAINT host_devices_venue_label_not_blank CHECK (venue_label IS NULL OR btrim(venue_label) <> ''),
  CONSTRAINT host_devices_app_version_not_blank CHECK (app_version IS NULL OR btrim(app_version) <> ''),
  CONSTRAINT host_devices_local_free_space_nonnegative CHECK (local_free_space_bytes IS NULL OR local_free_space_bytes >= 0),
  CONSTRAINT host_devices_local_library_root_not_blank CHECK (local_library_root IS NULL OR btrim(local_library_root) <> '')
);

CREATE INDEX IF NOT EXISTS idx_host_devices_active_last_seen
  ON hq_catalog.host_devices(is_active, last_seen_at DESC);

CREATE INDEX IF NOT EXISTS idx_host_devices_venue_label
  ON hq_catalog.host_devices(venue_label);

ALTER TABLE hq_catalog.authorized_media_files
  ADD COLUMN IF NOT EXISTS sync_manifest_priority integer NOT NULL DEFAULT 100,
  ADD COLUMN IF NOT EXISTS always_keep_on_host boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS server_archive_only boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS selected_host_device_ids uuid[] NOT NULL DEFAULT ARRAY[]::uuid[],
  ADD COLUMN IF NOT EXISTS requested_song_priority_boost integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS recently_used_priority_boost integer NOT NULL DEFAULT 0;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'authorized_media_files_sync_manifest_priority_nonnegative'
  ) THEN
    ALTER TABLE hq_catalog.authorized_media_files
      ADD CONSTRAINT authorized_media_files_sync_manifest_priority_nonnegative
      CHECK (sync_manifest_priority >= 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'authorized_media_files_requested_boost_nonnegative'
  ) THEN
    ALTER TABLE hq_catalog.authorized_media_files
      ADD CONSTRAINT authorized_media_files_requested_boost_nonnegative
      CHECK (requested_song_priority_boost >= 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'authorized_media_files_recently_used_boost_nonnegative'
  ) THEN
    ALTER TABLE hq_catalog.authorized_media_files
      ADD CONSTRAINT authorized_media_files_recently_used_boost_nonnegative
      CHECK (recently_used_priority_boost >= 0);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_authorized_media_files_host_manifest_flags
  ON hq_catalog.authorized_media_files(server_archive_only, always_keep_on_host, sync_manifest_priority);

CREATE INDEX IF NOT EXISTS idx_authorized_media_files_selected_hosts
  ON hq_catalog.authorized_media_files USING gin(selected_host_device_ids);

INSERT INTO hq_catalog.schema_migrations (version, description)
VALUES ('0003', 'host registration and sync manifest foundation')
ON CONFLICT (version) DO UPDATE
SET description = EXCLUDED.description;
