# HQ Server

This directory contains HQ server work.

Wave 1B adds the first protected catalog-management controls in `server/hq`.

## Supported framework

The supported HQ catalog runtime for this batch is Node.js using the built-in `node:http` server and the `pg` PostgreSQL client.

## Run the catalog API with PostgreSQL

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\start-local-stack.ps1
$env:DATABASE_URL = "postgresql://dandjs_demo:demo_password_placeholder@localhost:15432/dandjs_demo"
$env:HQ_ADMIN_TOKEN = "changeme-local-admin-token-placeholder"
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-hq-migrations.ps1 -Seed
Set-Location .\server\hq
npm install
npm start
```

By default the API listens on `http://localhost:5100`.

Public read-only routes in this batch:

- `GET /healthz`
- `GET /api/catalog/healthz`
- `GET /api/catalog/search`
- `GET /api/catalog/exact-match`
- `GET /api/catalog/songs/{songId}`
- `GET /api/catalog/songs/{songId}/alternate-versions`

Temporary protected routes require `HQ_ADMIN_TOKEN` from the environment:

- `POST /api/admin/catalog/songs`
- `PATCH /api/admin/catalog/songs/{songId}`
- `PUT /api/admin/catalog/songs/{songId}/preferred-version`
- `PATCH /api/admin/catalog/songs/{songId}/review-state`
- `PATCH /api/admin/catalog/songs/{songId}/source-notes`
- `POST /api/admin/catalog/songs/{songId}/retire`
- `GET /api/admin/catalog/audit`

## Explicit demo mode

The JSON catalog is only for development/demo mode:

```powershell
Set-Location .\server\hq
$env:DEMO_MODE = "true"
npm start
```

If `DATABASE_URL` is set, the API uses PostgreSQL. If neither `DATABASE_URL` nor explicit demo mode is set, startup fails instead of silently falling back to JSON fixtures.

## Database

PostgreSQL migrations and demo seed SQL live under `server/hq/database`.

```powershell
$env:DATABASE_URL = "postgresql://dandjs_demo:demo_password_placeholder@localhost:15432/dandjs_demo"
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-hq-migrations.ps1 -Seed
```

The migration pipeline records applied versions in `hq_catalog.schema_migrations`, checks tracking before applying each migration file, uses repeat-safe DDL guards, and keeps demo seed loading repeat-safe with `ON CONFLICT` handling.

## Development reset

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\reseed-hq-catalog.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\reset-hq-catalog.ps1 -Seed -ConfirmReset
```

## Batch boundary

Wave 1B does not add full staff authentication, host sync, Windows host features, playback, request screens, OBS, Replay, or external-source acquisition workflows.
