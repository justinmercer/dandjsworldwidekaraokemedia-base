# Run Only the HQ API

Wave 2A adds host registration, heartbeat state, admin host-status summaries, deterministic manifest planning, and review-first manifest diffs on top of the runnable HQ catalog API.

## Supported framework

The supported framework for this batch is Node.js with the built-in `node:http` server. The project path is `server/hq`.

## Start local dependencies

Start the local Postgres database:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\start-local-stack.ps1
```

## Apply migrations

```powershell
$env:DATABASE_URL = "postgresql://dandjs_demo:demo_password_placeholder@localhost:15432/dandjs_demo"
$env:HQ_ADMIN_TOKEN = "changeme-local-admin-token-placeholder"
$env:HQ_HOST_REGISTRATION_TOKEN = "changeme-local-host-registration-token-placeholder"
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-hq-migrations.ps1 -Seed
```

This applies tracked migrations under `server/hq/database/migrations` and, with `-Seed`, loads synthetic catalog seed metadata from `server/hq/database/seeds/0001_demo_catalog.sql`.

## Run the API

```powershell
Set-Location .\server\hq
npm install
npm start
```

The default local port is `5100`.

When `DATABASE_URL` is configured, the API uses PostgreSQL. The server does not silently fall back to JSON in PostgreSQL mode.

## Explicit demo mode

Use JSON demo metadata only when explicitly requested:

```powershell
Set-Location .\server\hq
$env:DEMO_MODE = "true"
npm start
```

If neither `DATABASE_URL` nor explicit demo mode is set, startup fails with a configuration error.

## Public routes

- `GET /healthz`
- `GET /api/catalog/healthz`
- `GET /api/catalog/search?query=demo&page=1&pageSize=20`
- `GET /api/catalog/exact-match?artist=Demo%20Artist&title=Demo%20Opening%20Song`
- `GET /api/catalog/songs/song_demo_opening`
- `GET /api/catalog/songs/song_demo_opening/alternate-versions`

Public responses intentionally omit `storageRelativeKey`, checksums, and filesystem paths in both PostgreSQL and demo modes. The API returns operator-authorized catalog metadata and opaque public identifiers only.

## Protected catalog-management routes

Protected routes require `HQ_ADMIN_TOKEN` from the runtime environment. There is no working default; if the token is missing, these routes fail closed.

- `POST /api/admin/catalog/songs`
- `PATCH /api/admin/catalog/songs/{songId}`
- `PUT /api/admin/catalog/songs/{songId}/preferred-version`
- `PATCH /api/admin/catalog/songs/{songId}/review-state`
- `PATCH /api/admin/catalog/songs/{songId}/source-notes`
- `POST /api/admin/catalog/songs/{songId}/retire`
- `GET /api/admin/catalog/audit`

## Protected host sync planning routes

Host routes require `HQ_HOST_REGISTRATION_TOKEN` from the runtime environment. There is no working default; if the token is missing, these routes fail closed.

- `POST /api/host/register`
- `POST /api/host/heartbeat`
- `GET /api/host/manifest?hostDeviceId={hostDeviceId}`
- `POST /api/host/manifest/diff`

Admin host status uses `HQ_ADMIN_TOKEN`:

- `GET /api/admin/hosts/status`

See [Host sync foundation](host-sync-foundation.md) for request and response examples. Host manifest planning returns opaque media keys and review-first diff candidates only; it does not download, transfer, play, or delete files.

## Reset and reseed

Repeat-safe reseed:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\reseed-hq-catalog.ps1
```

Development reset:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\reset-hq-catalog.ps1 -Seed -ConfirmReset
```

## Wave 2A limitation

This batch does not add full staff authentication, host downloading, local file transfer, Windows host UI, playback, request screens, OBS, Replay, cleanup deletion execution, synchronization progress/error reporting, or external-source acquisition workflows.
