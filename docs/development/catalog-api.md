# HQ Catalog API

The HQ catalog API exposes public catalog reads and temporary protected catalog-management routes for local development. Wave 2A keeps these routes and adds separate protected host sync-planning routes documented in [Host sync foundation](host-sync-foundation.md).

## Configuration

Run against PostgreSQL:

```powershell
$env:DATABASE_URL = "postgresql://dandjs_demo:demo_password_placeholder@localhost:15432/dandjs_demo"
$env:HQ_ADMIN_TOKEN = "changeme-local-admin-token-placeholder"
$env:HQ_HOST_REGISTRATION_TOKEN = "changeme-local-host-registration-token-placeholder"
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run-hq-migrations.ps1 -Seed
Set-Location .\server\hq
npm install
npm start
```

`HQ_ADMIN_TOKEN` must come from the environment. The server does not provide a working default. If it is missing, every `/api/admin/catalog/...` route fails closed with `admin_auth_not_configured`.

## Public catalog routes

Public routes are read-only and omit storage keys, checksums, and filesystem paths.

- `GET /healthz`
- `GET /api/catalog/healthz`
- `GET /api/catalog/search?query=demo&page=1&pageSize=20`
- `GET /api/catalog/exact-match?artist=Demo%20Artist&title=Demo%20Opening%20Song`
- `GET /api/catalog/songs/{songId}`
- `GET /api/catalog/songs/{songId}/alternate-versions`

Search supports `query`, `artist`, `title`, `page`, and `pageSize`. `pageSize` is capped server-side at 50. Public search has an in-memory development rate limit to prevent accidental hot loops.

## Temporary protected catalog-management routes

Send the temporary token as either `Authorization: Bearer <token>` or `X-HQ-Admin-Token: <token>`.

- `POST /api/admin/catalog/songs`
- `PATCH /api/admin/catalog/songs/{songId}`
- `PUT /api/admin/catalog/songs/{songId}/preferred-version`
- `PATCH /api/admin/catalog/songs/{songId}/review-state`
- `PATCH /api/admin/catalog/songs/{songId}/source-notes`
- `POST /api/admin/catalog/songs/{songId}/retire`
- `GET /api/admin/catalog/audit?entityType=song&entityId={songId}`

Every protected write records a structured audit row with action, entity, actor label, optional change reason, and before/after snapshots. The optional `X-Admin-Actor` and `X-Change-Reason` headers are for local traceability only and are not a replacement for the later staff-auth wave.

## Error shape

Errors use a user-safe envelope:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "artistName is required.",
    "correlationId": "request-correlation-id"
  }
}
```

Do not expose stack traces, storage mount paths, private URLs, real media paths, or credentials through API responses.
