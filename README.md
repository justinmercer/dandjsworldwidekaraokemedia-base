# D & J's Karaoke Software

D & J's Karaoke Software is planned as a local-first karaoke operations system for live shows. The host app must keep a show running without internet or cloud services, while future server and request components support authorized catalog management, guest requests, and optional integrations.

## Current status

This repository is in Wave 0A foundation mode. The current contents are documentation, repository scaffolding, safe environment examples, and placeholders only. There are no server APIs, Windows host features, playback features, synchronization jobs, mobile request flows, OBS companion code, or Replay integration code in this batch.

## Repository layout

| Path | Purpose |
| --- | --- |
| `host/` | Future Windows host application. README-only placeholder in Wave 0A. |
| `server/` | Future HQ server services. README-only placeholder in Wave 0A. |
| `apps/request-web/` | Future request web app. README-only placeholder in Wave 0A. |
| `packages/contracts/` | Future shared contracts and DTOs. README-only placeholder in Wave 0A. |
| `docs/` | Product, architecture, process, operator, and release documentation. |
| `infra/` | Future infrastructure and local development setup notes. |
| `tests/` | Future cross-service and smoke-test fixtures. |
| `scripts/` | Repo-wide helper scripts. |

## Development startup

There is no runnable product stack yet. For now, validate the foundation files with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\smoke-test.ps1
```

PowerShell 7 (`pwsh`) can run the same script if it is installed.

Future startup commands will be added as host, server, request-web, and shared-contract projects land in later backlog tasks.

## Safety boundaries

- Active karaoke playback must remain local-first and isolated from internet, server, OBS companion, and Replay outages.
- Only operator-owned or otherwise authorized karaoke media may be stored or synchronized.
- YouTube work is limited to official search and embedded preview review. This repository must not add arbitrary ripping or unattended download workflows.
- Demo placeholders are allowed. Real media, secrets, private URLs, and personal singer data are not.

## Planning documents

Start with:

- `docs/MASTER-BACKLOG-577.md`
- `docs/CODEX-EXECUTION-WAVES.md`
- `docs/README.md`
