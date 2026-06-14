# Shared Contracts Placeholder

This directory contains shared JSON Schema contracts for cross-component DTOs.

Wave 2A keeps the `v1` contract version and refines the host-device and synchronization-manifest schemas for protected HQ host sync planning. It does not add generated clients, playback logic, host downloading, local file transfer, cleanup deletion execution, OBS implementation, or Replay implementation.

## Current contract version

The initial foundation contract version is `v1`. See `VERSION.md` and `docs/architecture/contract-versioning.md`.

## Schemas

- `schemas/song-metadata.v1.schema.json`
- `schemas/singer-profile.v1.schema.json`
- `schemas/venue-profile.v1.schema.json`
- `schemas/show-session.v1.schema.json`
- `schemas/song-request.v1.schema.json`
- `schemas/host-device.v1.schema.json`
- `schemas/synchronization-manifest.v1.schema.json`
- `schemas/playback-state.v1.schema.json`
- `schemas/external-display-state.v1.schema.json`
- `schemas/obs-companion-event.v1.schema.json`
- `schemas/replay-event.v1.schema.json`
- `schemas/api-request-context.v1.schema.json`
- `schemas/service-health.v1.schema.json`
- `schemas/service-readiness.v1.schema.json`

Validate the schema files with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ..\..\scripts\validate-contracts.ps1
```
