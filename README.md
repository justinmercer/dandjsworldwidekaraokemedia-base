# D & J's Karaoke Software

D & J's Karaoke Software is planned as a local-first karaoke operations system for live shows. The host app must keep a show running without internet or cloud services, while future server and request components support authorized catalog management, guest requests, and optional integrations.

## Current status

This repository is in Wave 1A catalog foundation mode. The current contents include documentation, shared contract schemas, local-development guardrails, safe environment examples, PostgreSQL catalog migrations, and a runnable read-only HQ catalog API backed by safe demo metadata. There are no Windows host features, playback features, synchronization jobs, mobile request screens, OBS companion implementation, Replay integration code, external-source acquisition workflows, credentials, private URLs, venue network details, real karaoke media, or personal singer data in this batch.

## Repository layout

| Path | Purpose |
| --- | --- |
| `host/` | Future Windows host application. README-only placeholder plus command-line build guidance. |
| `server/` | HQ server workspace, including the runnable read-only catalog foundation in `server/hq`. |
| `apps/request-web/` | Future request web app. README-only placeholder plus development proxy configuration. |
| `packages/contracts/` | Shared JSON Schema contracts for future cross-component DTOs. |
| `docs/` | Product, architecture, process, operator, and release documentation. |
| `infra/` | Local development Compose, proxy, and observability placeholder configuration. |
| `tests/` | Cross-service smoke-test fixtures and safe demo seed data. |
| `scripts/` | Repo-wide helper scripts. |

## Development startup

Validate the foundation files with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\smoke-test.ps1
```

PowerShell 7 (`pwsh`) can run the same script if it is installed.

Run the read-only HQ catalog API against PostgreSQL:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\start-local-stack.ps1
$env:DATABASE_URL = "postgresql://dandjs_demo:demo_password_placeholder@localhost:15432/dandjs_demo"
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-hq-migrations.ps1 -Seed
Set-Location .\server\hq
npm install
npm start
```

Run the API with safe JSON demo metadata only when explicitly requested:

```powershell
Set-Location .\server\hq
$env:DEMO_MODE = "true"
npm start
```

The default local API base URL is `http://localhost:5100`. Useful endpoints are:

- `GET /healthz`
- `GET /api/catalog/search?query=demo&page=1&pageSize=20`
- `GET /api/catalog/exact-match?artist=Demo%20Artist&title=Demo%20Opening%20Song`
- `GET /api/catalog/songs/song_demo_opening`

The optional local development stack contains database and cache containers:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\start-local-stack.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\inspect-local-stack.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\stop-local-stack.ps1
```

Apply catalog migrations to a local Postgres database with:

```powershell
$env:DATABASE_URL = "postgresql://dandjs_demo:demo_password_placeholder@localhost:15432/dandjs_demo"
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-hq-migrations.ps1 -Seed
```

The migration and seed commands are repeat-safe. The CI integration check runs them twice against PostgreSQL.

## Safety boundaries

- Active karaoke playback must remain local-first and isolated from internet, server, OBS companion, and Replay outages.
- Only operator-owned or otherwise authorized karaoke media may be stored or synchronized.
- YouTube work is limited to official search and embedded preview review. This repository must not add arbitrary ripping or unattended download workflows.
- Public catalog endpoints are read-only in this batch and do not expose storage-relative keys or filesystem paths.
- Demo placeholders are allowed. Real media, secrets, private URLs, venue network details, and personal singer data are not.

## Planning documents

Start with:

- `docs/MASTER-BACKLOG-577.md`
- `docs/CODEX-EXECUTION-WAVES.md`
- `docs/README.md`
