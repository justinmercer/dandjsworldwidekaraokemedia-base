
# Host Local Persistence

Wave 3C adds the first local SQLite persistence schema for the Windows host.

This folder contains migration text only. It does not create or commit a real database file.

## Safety boundary

Wave 3C does not add:

- real media scanning
- playback
- file transfer
- file deletion
- server synchronization execution
- OBS connection behavior
- Replay connection behavior

## Tables introduced

- `local_schema_migrations`
- `local_song_cache`
- `local_singer_profiles`
- `local_show_sessions`
- `local_song_requests`
- `local_venue_profiles`
- `local_sync_status`

The schema is designed for local-first operation so the host can continue planning show data while offline.
