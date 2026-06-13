# Local Development Stack

Wave 0B includes a local-only Docker Compose stack for future HQ API development.

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

## Seed demo data

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\load-demo-seed.ps1
```

The seed loader validates safe demo fixtures and writes a local artifact summary. It does not insert database rows because Wave 1 database schemas are intentionally not part of Wave 0B.

## Limitation

This stack does not include an HQ API container, request web app, Windows host, media storage service, synchronization worker, OBS adapter, or Replay adapter.
