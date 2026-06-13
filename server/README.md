# HQ Server

This directory contains HQ server work.

Wave 1A adds the first runnable catalog foundation in `server/hq`.

## Supported framework

The supported HQ catalog runtime for this batch is Node.js using the built-in `node:http` server. The project intentionally has no runtime package dependencies yet.

## Run the catalog API

```powershell
Set-Location .\server\hq
npm test
npm start
```

By default the API listens on `http://localhost:5100`.

Public read-only routes in this batch:

- `GET /healthz`
- `GET /api/catalog/healthz`
- `GET /api/catalog/search`
- `GET /api/catalog/exact-match`
- `GET /api/catalog/songs/{songId}`

## Database

PostgreSQL migrations and demo seed SQL live under `server/hq/database`.

```powershell
$env:DATABASE_URL = "postgresql://dandjs_demo:demo_password_placeholder@localhost:15432/dandjs_demo"
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-hq-migrations.ps1 -Seed
```

The runnable API uses `server/hq/data/demo-catalog.json` so it can be exercised without committing credentials or requiring a local database in every validation environment.

## Batch boundary

Wave 1A does not add admin write endpoints, alternate-version listing endpoints, authentication, Windows host features, playback, syncing, request screens, OBS, Replay, or external-source acquisition workflows.
