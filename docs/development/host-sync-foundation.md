# Host Sync Foundation

Wave 2A adds HQ-side host registration and deterministic manifest planning only. It does not download files, transfer files, play media, run cleanup deletion, create Windows UI, add singer request screens, or make server sync a live-show dependency.

## Configuration

Host registration and host sync-planning routes require a development registration token from the runtime environment:

```powershell
$env:HQ_HOST_REGISTRATION_TOKEN = "changeme-local-host-registration-token-placeholder"
```

There is no working default token. If `HQ_HOST_REGISTRATION_TOKEN` is missing, `/api/host/...` routes fail closed with `host_registration_not_configured`. Send the token as either `Authorization: Bearer <token>` or `X-HQ-Host-Registration-Token: <token>`.

Admin host-status routes use the existing temporary `HQ_ADMIN_TOKEN` boundary. That is still a development-only boundary until the later staff-auth wave.

## Host Registration

Register or refresh a host record:

```http
POST /api/host/register
Authorization: Bearer changeme-local-host-registration-token-placeholder
Content-Type: application/json

{
  "displayName": "Demo Booth Laptop",
  "venueLabel": "Demo Venue",
  "appVersion": "0.2.0-demo",
  "localFreeSpaceBytes": 987654321,
  "localLibraryRoot": "C:\\Demo\\Karaoke"
}
```

The response intentionally redacts the local library root:

```json
{
  "hostDevice": {
    "contractVersion": "v1",
    "hostDeviceId": "generated-or-supplied-id",
    "displayName": "Demo Booth Laptop",
    "venueLabel": "Demo Venue",
    "appVersion": "0.2.0-demo",
    "localFreeSpaceBytes": 987654321,
    "localLibraryRootReported": true,
    "isActive": true,
    "syncState": "idle"
  }
}
```

## Heartbeats

Heartbeat updates may report app version, free space, a local library root, active/inactive state, and an interrupted-sync marker:

```json
{
  "hostDeviceId": "generated-or-supplied-id",
  "appVersion": "0.2.1-demo",
  "localFreeSpaceBytes": 987650000,
  "isActive": true,
  "syncState": "interrupted",
  "interruptedSyncState": {
    "syncId": "sync-demo-001",
    "reason": "Synthetic interrupted sync marker.",
    "lastMediaKey": "authorized-media:media_demo_opening_cdg",
    "interruptedAt": "2026-06-14T00:00:00Z"
  }
}
```

Wave 2A tracks interrupted state only. Progress reporting, error reporting, pause/resume/cancel, verification, and host-side retry behavior begin at `KARA-136` or later and are intentionally not implemented here.

## Admin Host Status

```http
GET /api/admin/hosts/status
Authorization: Bearer changeme-local-admin-token-placeholder
```

The status response is a protected HQ admin API placeholder for a later real UI. It returns safe host summaries and does not include raw local library paths.

## Manifest Planning

```http
GET /api/host/manifest?hostDeviceId=generated-or-supplied-id
Authorization: Bearer changeme-local-host-registration-token-placeholder
```

Manifest entries are deterministic and include only authorized-media planning fields:

```json
{
  "songId": "song_demo_opening",
  "authorizedMediaId": "media_demo_opening_cdg",
  "mediaKey": "authorized-media:media_demo_opening_cdg",
  "sha256Checksum": "1111111111111111111111111111111111111111111111111111111111111111",
  "fileSizeBytes": 12582912,
  "priority": 1160,
  "versionTimestamp": "2026-06-13T00:00:00Z",
  "flags": {
    "alwaysKeepOnHost": true,
    "serverArchiveOnly": false,
    "selectedHostSync": false
  }
}
```

Manifest ordering is stable: higher priority first, then song ID, then media key. Entries expose opaque `mediaKey` values, checksums, size, version timestamps, and planning flags. They do not expose storage-relative keys, filesystem paths, private URLs, or transfer instructions.

The planning rules are:

- `serverArchiveOnly` media is excluded from host manifests.
- `selectedHostDeviceIds` limits media to selected hosts.
- `alwaysKeepOnHost` boosts priority but does not create a download action.
- requested-song and recently-used boosts are deterministic metadata inputs only; Wave 2A does not add real singer request data.

## Manifest Diff

```http
POST /api/host/manifest/diff
Authorization: Bearer changeme-local-host-registration-token-placeholder
Content-Type: application/json

{
  "hostDeviceId": "generated-or-supplied-id",
  "currentEntries": []
}
```

The diff response represents additions, updates, and review-first cleanup candidates:

```json
{
  "additions": [{ "action": "add" }],
  "updates": [{ "action": "update" }],
  "cleanupCandidates": [
    {
      "action": "review_cleanup_candidate",
      "reviewRequired": true,
      "deleteReady": false,
      "reason": "not_in_target_manifest"
    }
  ]
}
```

Cleanup candidates are never deletion commands. A later wave must add review UI and explicit operator confirmation before any destructive cleanup behavior exists.
