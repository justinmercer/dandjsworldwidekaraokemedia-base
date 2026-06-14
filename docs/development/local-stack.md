# Local Development Stack

Wave 2A uses the local-only Docker Compose stack for HQ catalog migration, protected API integration checks, host registration, and manifest-planning checks.

## Prerequisites

- Docker Desktop or Docker Engine with the Compose plugin.
- PowerShell 5.1 or PowerShell 7.

## Start

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\start-local-stack.ps1
```

This starts:

- `hq-db`: Postgres on local port `15432`.
- `hq-cache`: Redis on local port `16379`.

Both services use demo-only credentials and local Docker volumes. They are not production settings.

## Inspect

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\inspect-local-stack.ps1
```

## Stop

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\stop-local-stack.ps1
```

## Reset

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\reset-local-stack.ps1
```

Reset removes the local Compose volumes. Do not use it for real data.

## Validate Compose syntax

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-docker-compose.ps1
```

The validation script runs `docker compose config --quiet` when Docker is available and skips with a clear message when Docker is not installed.

## Apply catalog migrations and seed data

```powershell
$env:DATABASE_URL = "postgresql://dandjs_demo:demo_password_placeholder@localhost:15432/dandjs_demo"
$env:HQ_HOST_REGISTRATION_TOKEN = "changeme-local-host-registration-token-placeholder"
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-hq-migrations.ps1 -Seed
```

The SQL seed data is synthetic and references opaque storage keys only. It does not include real karaoke files, credentials, private URLs, venue network details, or personal singer data.

The migration command is safe to run more than once. CI verifies this by running migrations and seed loading twice before exercising the database-backed API.

## Summarize demo fixtures

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\load-demo-seed.ps1
```

This writes a local artifact summary for demo fixtures and catalog seed metadata. It does not require a database.

## Live integration check

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-hq-postgres-integration.ps1
```

This starts local PostgreSQL, waits for readiness, runs migrations with seed data twice, verifies catalog counts through the API health response, exercises public search, exact-match, song-detail, alternate-version, protected write, normalization, audit-history, host registration, heartbeat, admin host-status, manifest, and manifest-diff paths, and stops the Compose service afterward.

## Limitation

This stack does not include an HQ API container, request web app, Windows host, media storage service, synchronization worker, file-transfer worker, playback engine, OBS adapter, or Replay adapter.
