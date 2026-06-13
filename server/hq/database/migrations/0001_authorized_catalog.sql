CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS hq_catalog;

CREATE TABLE IF NOT EXISTS hq_catalog.schema_migrations (
  version text PRIMARY KEY,
  description text NOT NULL,
  applied_at timestamptz NOT NULL DEFAULT now()
);

DO $$
BEGIN
  CREATE TYPE hq_catalog.provider_source_type AS ENUM (
    'operator_authorized',
    'licensed_partner',
    'legacy_import',
    'manual_entry'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE hq_catalog.catalog_review_state AS ENUM (
    'pending_review',
    'approved',
    'rejected',
    'needs_metadata',
    'retired'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE hq_catalog.media_file_format AS ENUM (
    'cdg_mp3_bundle',
    'mp4_karaoke',
    'webm_karaoke',
    'zip_bundle',
    'other'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE hq_catalog.vocal_guide_type AS ENUM (
    'none',
    'guide_vocal',
    'background_vocals',
    'duet',
    'unknown'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE hq_catalog.alternate_version_relationship_type AS ENUM (
    'alternate_arrangement',
    'different_key',
    'radio_edit',
    'extended_version',
    'language_variant',
    'other'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS hq_catalog.catalog_providers (
  provider_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_code text NOT NULL UNIQUE,
  display_name text NOT NULL,
  source_type hq_catalog.provider_source_type NOT NULL,
  authorization_notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  retired_at timestamptz,
  retirement_reason text,
  CONSTRAINT catalog_providers_provider_code_not_blank CHECK (btrim(provider_code) <> ''),
  CONSTRAINT catalog_providers_display_name_not_blank CHECK (btrim(display_name) <> '')
);

CREATE TABLE IF NOT EXISTS hq_catalog.songs (
  song_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  artist_name text NOT NULL,
  normalized_title text NOT NULL,
  normalized_artist text NOT NULL,
  language_code text NOT NULL DEFAULT 'und',
  preferred_authorized_media_id uuid,
  review_state hq_catalog.catalog_review_state NOT NULL DEFAULT 'pending_review',
  quality_rating smallint,
  authorization_notes text,
  last_verified_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  retired_at timestamptz,
  retirement_reason text,
  CONSTRAINT songs_title_not_blank CHECK (btrim(title) <> ''),
  CONSTRAINT songs_artist_name_not_blank CHECK (btrim(artist_name) <> ''),
  CONSTRAINT songs_normalized_title_not_blank CHECK (btrim(normalized_title) <> ''),
  CONSTRAINT songs_normalized_artist_not_blank CHECK (btrim(normalized_artist) <> ''),
  CONSTRAINT songs_quality_rating_range CHECK (quality_rating IS NULL OR quality_rating BETWEEN 1 AND 5)
);

CREATE TABLE IF NOT EXISTS hq_catalog.authorized_media_files (
  authorized_media_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  song_id uuid NOT NULL REFERENCES hq_catalog.songs(song_id) ON DELETE RESTRICT,
  provider_id uuid NOT NULL REFERENCES hq_catalog.catalog_providers(provider_id) ON DELETE RESTRICT,
  provider_track_id text,
  sha256_checksum char(64) NOT NULL,
  file_size_bytes bigint NOT NULL,
  duration_seconds integer NOT NULL,
  file_format hq_catalog.media_file_format NOT NULL,
  vocal_guide_type hq_catalog.vocal_guide_type NOT NULL DEFAULT 'unknown',
  storage_relative_key text NOT NULL,
  is_preferred_version boolean NOT NULL DEFAULT false,
  review_state hq_catalog.catalog_review_state NOT NULL DEFAULT 'pending_review',
  quality_rating smallint,
  authorization_notes text,
  last_verified_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  retired_at timestamptz,
  retirement_reason text,
  CONSTRAINT authorized_media_files_sha256_format CHECK (sha256_checksum ~ '^[0-9a-f]{64}$'),
  CONSTRAINT authorized_media_files_file_size_positive CHECK (file_size_bytes > 0),
  CONSTRAINT authorized_media_files_duration_positive CHECK (duration_seconds > 0),
  CONSTRAINT authorized_media_files_quality_rating_range CHECK (quality_rating IS NULL OR quality_rating BETWEEN 1 AND 5),
  CONSTRAINT authorized_media_files_storage_key_relative CHECK (
    btrim(storage_relative_key) <> ''
    AND storage_relative_key !~ '(^/|^[A-Za-z]:|^\\\\|(^|/)\\.\\.(/|$))'
  )
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'songs_preferred_authorized_media_id_fk'
      AND conrelid = 'hq_catalog.songs'::regclass
  ) THEN
    ALTER TABLE hq_catalog.songs
      ADD CONSTRAINT songs_preferred_authorized_media_id_fk
      FOREIGN KEY (preferred_authorized_media_id)
      REFERENCES hq_catalog.authorized_media_files(authorized_media_id)
      DEFERRABLE INITIALLY DEFERRED;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS hq_catalog.alternate_version_relationships (
  relationship_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  song_id uuid NOT NULL REFERENCES hq_catalog.songs(song_id) ON DELETE RESTRICT,
  alternate_song_id uuid NOT NULL REFERENCES hq_catalog.songs(song_id) ON DELETE RESTRICT,
  relationship_type hq_catalog.alternate_version_relationship_type NOT NULL,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  retired_at timestamptz,
  retirement_reason text,
  CONSTRAINT alternate_version_relationships_distinct_songs CHECK (song_id <> alternate_song_id),
  CONSTRAINT alternate_version_relationships_unique_pair UNIQUE (song_id, alternate_song_id, relationship_type)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_authorized_media_files_one_preferred_per_song
  ON hq_catalog.authorized_media_files(song_id)
  WHERE is_preferred_version AND retired_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_songs_normalized_artist_title
  ON hq_catalog.songs(normalized_artist, normalized_title)
  WHERE retired_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_songs_normalized_title_artist
  ON hq_catalog.songs(normalized_title, normalized_artist)
  WHERE retired_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_authorized_media_files_sha256_checksum
  ON hq_catalog.authorized_media_files(sha256_checksum)
  WHERE retired_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_authorized_media_files_sync_manifest
  ON hq_catalog.authorized_media_files(updated_at, last_verified_at, song_id)
  WHERE retired_at IS NULL AND review_state = 'approved';

CREATE INDEX IF NOT EXISTS idx_songs_sync_manifest
  ON hq_catalog.songs(updated_at, song_id)
  WHERE retired_at IS NULL AND review_state = 'approved';

CREATE INDEX IF NOT EXISTS idx_alternate_versions_sync_manifest
  ON hq_catalog.alternate_version_relationships(updated_at, song_id, alternate_song_id)
  WHERE retired_at IS NULL;

INSERT INTO hq_catalog.schema_migrations (version, description)
VALUES ('0001', 'authorized catalog foundation')
ON CONFLICT (version) DO UPDATE
SET description = EXCLUDED.description;
