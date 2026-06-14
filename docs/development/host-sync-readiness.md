
# Host Sync Readiness

Host synchronization is currently planning-only and metadata-only.

The HQ server can register host laptops, receive heartbeat metadata, create target manifests, compare current host manifest entries, store sync-control state, queue operator actions, summarize sync state, and record verification/quarantine metadata.

The live karaoke show remains local-first. A show must continue during internet, server, OBS companion, or Replay outages.

## Safety boundaries

The current implementation must not:

- download media to a host
- delete media from a host
- move local files
- play karaoke tracks
- depend on OBS or Replay
- expose Windows library roots through public or admin-safe responses
- store real media in the repository
- add YouTube ripping or unattended download behavior

All sync tests use synthetic demo fixtures and metadata only.

## Covered readiness areas

Wave 2 sync readiness now covers host registration, heartbeat, status listing, deterministic manifests, manifest additions, updates, review-first cleanup candidates, progress metadata, error metadata, pause/resume/cancel action metadata, capacity metadata, checksum verification metadata, quarantine metadata, interrupted operation metadata, retry/backoff metadata, operator summary metadata, Sync Now, Verify Library, View Missing Locally, and Review Cleanup Candidates.

## Operator controls

The following controls are represented as safe queued actions only:

- Sync Now
- Verify Library
- View Missing Locally
- Review Cleanup Candidates
- Pause Sync
- Resume Sync
- Cancel Pending Noncritical

Queued actions are instructions for a future host app to review. They do not perform file transfer, file deletion, or playback by themselves.

## Readiness test

Run from the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\sync-readiness-smoke-test.ps1
```
