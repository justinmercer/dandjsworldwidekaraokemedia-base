# HQ Migration Rollback

Wave 2A keeps migrations forward-only for the development catalog and host-sync planning tables. Full production rollback policy belongs to the later backup and restore waves.

## Development reset

For local development databases only, reset the HQ catalog schema and reload synthetic seed metadata:

```powershell
$env:DATABASE_URL = "postgresql://dandjs_demo:demo_password_placeholder@localhost:15432/dandjs_demo"
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\reset-hq-catalog.ps1 -Seed -ConfirmReset
```

`-ConfirmReset` is required because the script drops the `hq_catalog` schema before rebuilding it.

## Repeat-safe reseed

To re-run migrations and repeat-safe demo seed SQL without dropping the schema:

```powershell
$env:DATABASE_URL = "postgresql://dandjs_demo:demo_password_placeholder@localhost:15432/dandjs_demo"
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\reseed-hq-catalog.ps1
```

The migration runner checks `hq_catalog.schema_migrations` before applying each migration file and skips versions that are already tracked.

## Wave 2A schema notes

Migration `0003_host_sync_foundation.sql` adds `hq_catalog.host_devices` and sync-planning metadata columns on `hq_catalog.authorized_media_files`. The new fields are planning metadata only:

- `local_library_root` stores host-reported local configuration for HQ diagnostics, but API responses expose only `localLibraryRootReported`.
- `server_archive_only` excludes media from host manifests.
- `selected_host_device_ids` limits manifest entries to selected hosts.
- priority boost columns are deterministic inputs and do not use real singer data in this wave.
- interrupted-sync state tracks the last safe marker only; it does not add progress reporting or retry execution.

## Manual rollback expectations

Until production backup workflows exist:

- do not use rollback scripts against real operator data
- snapshot or export the database before testing destructive changes
- prefer forward corrective migrations over editing applied migration files
- keep demo seed data synthetic and repeat-safe

If a development migration fails, reset the local schema, re-run migrations, and inspect the failing SQL before opening a pull request.
