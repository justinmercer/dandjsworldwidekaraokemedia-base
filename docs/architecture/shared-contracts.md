# Shared Contracts

Shared contracts describe the DTO shapes components will exchange. They are stored as JSON Schema files in `packages/contracts/schemas`.

## Contract inventory

| Backlog task | Contract | Schema |
| --- | --- | --- |
| `KARA-028` | Canonical song metadata | `song-metadata.v1.schema.json` |
| `KARA-029` | Singer profile | `singer-profile.v1.schema.json` |
| `KARA-030` | Venue profile | `venue-profile.v1.schema.json` |
| `KARA-031` | Show session | `show-session.v1.schema.json` |
| `KARA-032` | Song request | `song-request.v1.schema.json` |
| `KARA-033` | Host device | `host-device.v1.schema.json` |
| `KARA-034` | Synchronization manifest | `synchronization-manifest.v1.schema.json` |
| `KARA-035` | Playback state | `playback-state.v1.schema.json` |
| `KARA-036` | External display state | `external-display-state.v1.schema.json` |
| `KARA-037` | OBS companion event | `obs-companion-event.v1.schema.json` |
| `KARA-038` | Replay event | `replay-event.v1.schema.json` |

Supporting contracts define request context, health, and readiness response shapes.

## Design rules

- Every schema includes `contractVersion` with the current value `v1`.
- Every schema uses JSON Schema draft 2020-12.
- Identifiers are opaque strings. They must not expose filesystem paths, private URLs, access tokens, or personal data.
- Media references are opaque authorized-media identifiers only. The repository must never include karaoke media files.
- Contracts can include future-facing fields, but they must not imply runtime features beyond the current Wave 1B catalog foundation.

## Validation

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-contracts.ps1
```

The validator checks schema JSON syntax, required metadata, `v1` identifiers, and the `contractVersion` constant. It does not replace full runtime validation inside future services.
