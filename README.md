# D & J's Karaoke Software

D & J's Karaoke Software is planned as a local-first karaoke operations system for live shows. The host app must keep a show running without internet or cloud services, while future server and request components support authorized catalog management, guest requests, and optional integrations.

## Current status

This repository is in Wave 0B foundation mode. The current contents are documentation, repository scaffolding, shared contract schemas, local-development guardrails, safe environment examples, and placeholders only. There are no production server APIs, Windows host features, playback features, synchronization jobs, mobile request screens, OBS companion implementation, or Replay integration code in this batch.

## Repository layout

| Path | Purpose |
| --- | --- |
| `host/` | Future Windows host application. README-only placeholder plus command-line build guidance in Wave 0B. |
| `server/` | Future HQ server services. README-only placeholder plus local-development notes in Wave 0B. |
| `apps/request-web/` | Future request web app. README-only placeholder plus development proxy configuration in Wave 0B. |
| `packages/contracts/` | Shared JSON Schema contracts for future cross-component DTOs. |
| `docs/` | Product, architecture, process, operator, and release documentation. |
| `infra/` | Local development Compose, proxy, and observability placeholder configuration. |
| `tests/` | Cross-service smoke-test fixtures and safe demo seed data. |
| `scripts/` | Repo-wide helper scripts. |

## Development startup

There is no runnable product application stack yet. For now, validate the foundation files with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\smoke-test.ps1
```

PowerShell 7 (`pwsh`) can run the same script if it is installed.

The optional local development stack contains only database and cache containers for later HQ API work:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\start-local-stack.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\inspect-local-stack.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\stop-local-stack.ps1
```

Future startup commands will be added as host, server, request-web, and implementation projects land in later backlog tasks.

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
