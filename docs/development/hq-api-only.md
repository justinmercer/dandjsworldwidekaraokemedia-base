# Run Only the HQ API

Wave 1A adds the first runnable read-only HQ catalog API.

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
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-hq-migrations.ps1 -Seed
```

This applies `server/hq/database/migrations/0001_authorized_catalog.sql` and, with `-Seed`, loads synthetic catalog seed metadata from `server/hq/database/seeds/0001_demo_catalog.sql`.

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

## Read-only routes

- `GET /healthz`
- `GET /api/catalog/healthz`
- `GET /api/catalog/search?query=demo&page=1&pageSize=20`
- `GET /api/catalog/exact-match?artist=Demo%20Artist&title=Demo%20Opening%20Song`
- `GET /api/catalog/songs/song_demo_opening`

Public responses intentionally omit `storageRelativeKey`, checksums, and filesystem paths in both PostgreSQL and demo modes. The API returns operator-authorized catalog metadata and opaque public identifiers only.

## Wave 1A limitation

This batch does not add admin write endpoints, alternate-version listing endpoints, authentication, synchronization endpoints, Windows host features, playback, request screens, OBS, Replay, or external-source acquisition workflows.
