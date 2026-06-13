# Service Boundaries and Data Ownership

This document defines ownership boundaries for later implementation. In Wave 0B these are contracts and review rules only.

## Component responsibilities

| Component | Owns | Reads from | Does not own |
| --- | --- | --- | --- |
| Windows host app | Active show state, local playback state, local display state, local diagnostics, offline-safe host cache | Future HQ manifests and request queues when available | HQ administration, global catalog edits, public request web UI, OBS or Replay uptime |
| HQ server | Future authorized catalog metadata, venue profiles, host registration records, synchronization manifests, request coordination, reports | Host status reports and request web submissions when implemented | Live playback authority or emergency show continuity |
| Request web app | Future guest request session UI state and request submission drafts | Future public catalog/search APIs | Catalog ownership, singer identity source of truth, playback, moderation final authority |
| Shared contracts package | Versioned DTO and JSON Schema definitions | Product and architecture decisions | Runtime business logic or persistence |
| OBS companion boundary | Future optional display/event exports | Host event stream when enabled | Host playback, show control, or required show operation |
| Replay boundary | Future optional performance event handoff | Approved host performance events when enabled | Playback, catalog ownership, or required show operation |

## Data ownership

| Data type | Primary owner | Wave 0B artifact | Notes |
| --- | --- | --- | --- |
| Song metadata | Future HQ server | `song-metadata.v1.schema.json` | Metadata only. No media files or media URLs. |
| Singer profile | Future HQ server with host-local cache | `singer-profile.v1.schema.json` | Use minimal display information. Avoid personal details unless explicitly required later. |
| Venue profile | Future HQ server | `venue-profile.v1.schema.json` | No private network details in source control. |
| Show session | Windows host app during active show | `show-session.v1.schema.json` | Host remains authoritative while a show is active. |
| Request | Future request web app creates, host moderates | `song-request.v1.schema.json` | Submission and moderation behavior is future work. |
| Host device | Future HQ server registration plus host local identity | `host-device.v1.schema.json` | Registration APIs are not part of Wave 0B. |
| Synchronization manifest | Future HQ server generates, host verifies | `synchronization-manifest.v1.schema.json` | No sync jobs or catalog DB are added here. |
| Playback state | Windows host app | `playback-state.v1.schema.json` | Contract only. No playback engine work. |
| External display state | Windows host app | `external-display-state.v1.schema.json` | Contract only. No display windows. |
| OBS event | Windows host app emits only when optional feature is enabled | `obs-companion-event.v1.schema.json` | Optional, failure-isolated future boundary. |
| Replay event | Windows host app emits only when optional feature is enabled | `replay-event.v1.schema.json` | Optional, failure-isolated future boundary. |
| Request context | Future server middleware | `api-request-context.v1.schema.json` | Defines correlation IDs only. |
| Health and readiness | Future server-side services | `service-health.v1.schema.json`, `service-readiness.v1.schema.json` | Defines response shape only. |

## Review rules

- Do not move live-show authority away from the host app without an ADR.
- Do not put real media, credentials, private URLs, venue network details, or personal singer information in fixtures or docs.
- Treat future integrations as optional. A failed integration must not block a live show.
- Keep Wave 1 database work out of Wave 0B. These ownership notes do not create tables, migrations, or production APIs.
