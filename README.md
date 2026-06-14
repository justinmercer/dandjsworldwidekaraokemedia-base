# D & J's Karaoke Software

D & J's Karaoke Software is planned as a local-first karaoke operations system for live shows. The host app must keep a show running without internet or cloud services, while future server and request components support authorized catalog management, guest requests, and optional integrations.

## Current status

This repository is in Wave 2A host-sync-foundation mode. The current contents include documentation, shared contract schemas, local-development guardrails, safe environment examples, PostgreSQL catalog migrations, a runnable HQ catalog API, protected development-only catalog-management routes, audit-history support, host registration, host heartbeat state, admin host-status summaries, and deterministic host manifest planning backed by safe demo metadata. There are no host downloading features, local file transfer features, playback features, Windows UI, mobile request screens, OBS companion implementation, Replay integration code, cleanup deletion execution, external-source acquisition workflows, credentials, private URLs, venue network details, real karaoke media, or personal singer data in this batch.

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

Run the HQ catalog API against PostgreSQL:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\start-local-stack.ps1
$env:DATABASE_URL = "postgresql://dandjs_demo:demo_password_placeholder@localhost:15432/dandjs_demo"
$env:HQ_ADMIN_TOKEN = "changeme-local-admin-token-placeholder"
$env:HQ_HOST_REGISTRATION_TOKEN = "changeme-local-host-registration-token-placeholder"
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
- `GET /api/catalog/songs/song_demo_opening/alternate-versions`
- `POST /api/host/register`
- `POST /api/host/heartbeat`
- `GET /api/host/manifest?hostDeviceId={hostDeviceId}`
- `POST /api/host/manifest/diff`
- `GET /api/admin/hosts/status`

Protected catalog-management and audit-history routes require `HQ_ADMIN_TOKEN` from the runtime environment. If the token is absent, admin routes fail closed.
Host registration and host manifest routes require `HQ_HOST_REGISTRATION_TOKEN` from the runtime environment. If the token is absent, host routes fail closed.

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

Development reset and reseed tools:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\reseed-hq-catalog.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\reset-hq-catalog.ps1 -Seed -ConfirmReset
```

## Safety boundaries

- Active karaoke playback must remain local-first and isolated from internet, server, OBS companion, and Replay outages.
- Only operator-owned or otherwise authorized karaoke media may be stored or synchronized.
- YouTube work is limited to official search and embedded preview review. This repository must not add arbitrary ripping or unattended download workflows.
- Public catalog endpoints are read-only and do not expose storage-relative keys, checksums, or filesystem paths.
- Host manifest planning exposes opaque media keys and review-first diff candidates only. It does not download, transfer, play, or delete files.
- Catalog-management and audit-history endpoints are protected by the temporary development admin boundary until the later staff-auth wave.
- Demo placeholders are allowed. Real media, secrets, private URLs, venue network details, and personal singer data are not.

## Planning documents

Start with:

- `docs/MASTER-BACKLOG-577.md`
- `docs/CODEX-EXECUTION-WAVES.md`
- `docs/README.md`
