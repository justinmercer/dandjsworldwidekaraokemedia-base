
-- D & J's Karaoke host local persistence schema.
-- Wave 3C only defines SQLite migration text. It does not create, commit, or ship a database file.

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS local_schema_migrations (
  migration_id TEXT PRIMARY KEY,
  applied_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS local_venue_profiles (
  venue_id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  display_order INTEGER NOT NULL DEFAULT 0,
  is_default INTEGER NOT NULL DEFAULT 0 CHECK (is_default IN (0, 1)),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS local_singer_profiles (
  singer_id TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  normalized_name TEXT NOT NULL,
  rotation_notes TEXT NOT NULL DEFAULT '',
  is_blocked INTEGER NOT NULL DEFAULT 0 CHECK (is_blocked IN (0, 1)),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS local_song_cache (
  song_id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  artist TEXT NOT NULL,
  normalized_title TEXT NOT NULL,
  normalized_artist TEXT NOT NULL,
  media_key TEXT,
  checksum_sha256 TEXT,
  duration_seconds INTEGER,
  is_available_locally INTEGER NOT NULL DEFAULT 0 CHECK (is_available_locally IN (0, 1)),
  review_needed INTEGER NOT NULL DEFAULT 0 CHECK (review_needed IN (0, 1)),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS local_show_sessions (
  show_session_id TEXT PRIMARY KEY,
  venue_id TEXT REFERENCES local_venue_profiles(venue_id) ON DELETE SET NULL,
  show_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'active', 'paused', 'closed')),
  started_at TEXT,
  ended_at TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS local_song_requests (
  request_id TEXT PRIMARY KEY,
  show_session_id TEXT NOT NULL REFERENCES local_show_sessions(show_session_id) ON DELETE CASCADE,
  singer_id TEXT REFERENCES local_singer_profiles(singer_id) ON DELETE SET NULL,
  song_id TEXT REFERENCES local_song_cache(song_id) ON DELETE SET NULL,
  request_status TEXT NOT NULL DEFAULT 'pending' CHECK (request_status IN ('pending', 'approved', 'queued', 'sung', 'skipped', 'cancelled')),
  requested_title TEXT NOT NULL DEFAULT '',
  requested_artist TEXT NOT NULL DEFAULT '',
  rotation_position INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS local_sync_status (
  sync_status_id TEXT PRIMARY KEY,
  host_device_id TEXT NOT NULL,
  sync_area TEXT NOT NULL CHECK (sync_area IN ('catalog', 'singers', 'venues', 'requests', 'settings')),
  sync_state TEXT NOT NULL DEFAULT 'local-only' CHECK (sync_state IN ('online', 'local-only', 'offline', 'syncing', 'failed', 'review-needed')),
  last_success_at TEXT,
  last_attempt_at TEXT,
  last_error_code TEXT,
  last_error_message TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_local_song_cache_search
  ON local_song_cache (normalized_artist, normalized_title);

CREATE INDEX IF NOT EXISTS idx_local_singer_profiles_name
  ON local_singer_profiles (normalized_name);

CREATE INDEX IF NOT EXISTS idx_local_song_requests_session_status
  ON local_song_requests (show_session_id, request_status, rotation_position);

CREATE INDEX IF NOT EXISTS idx_local_sync_status_host_area
  ON local_sync_status (host_device_id, sync_area);

INSERT OR IGNORE INTO local_schema_migrations (migration_id)
VALUES ('0001_local_host_schema');
