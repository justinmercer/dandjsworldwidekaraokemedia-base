# Host App Placeholder

This directory now contains the first safe Windows host shell under `host/windows-host-shell`.

Wave 3A adds a local-first host shell with dashboard placeholders only. It intentionally adds no playback, local database, synchronization execution, OBS companion, or Replay behavior.

Use `host/.env.example` for safe demo-only configuration placeholders when the host project is created.

Command-line build expectations are documented in `docs/development/windows-host-cli-build.md`; the current shell decision is documented in `docs/development/windows-host-shell.md`.


## Local persistence

The first SQLite schema migration text lives under `host/local-persistence`. It is schema-only and does not create or commit a real database file.
