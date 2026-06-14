
# Host Local Persistence

Wave 3C adds the first local SQLite persistence plan for the Windows host.

## Purpose

The host app must stay useful during live shows even when the internet, HQ server, OBS, and Replay are unavailable. The local persistence schema is the start of that local-first foundation.

## Migration

The first migration is:

```text
host/local-persistence/migrations/0001_local_host_schema.sql
```

It defines:

- local schema migration tracking
- song cache table
- singer profile table
- show session table
- request table
- venue profile table
- sync status table

## Safety boundary

Wave 3C is schema-only. It does not create a real database file and does not scan, move, download, play, or delete media.
