# Naming Conventions

Use consistent names so later services, contracts, routes, and tables are easy to review.

## Services and packages

- `host-app`: Windows host application.
- `hq-server`: server-side catalog APIs now, with administration, sync, and request APIs reserved for later tasks.
- `request-web`: guest request web app.
- `shared-contracts`: cross-component DTOs, schemas, and versioned API contracts.
- `infra`: local development and deployment support files.

Use kebab case for service and package folder names.

## Endpoints

Server APIs should use:

- Use `/api/v1` as the first versioned API prefix.
- Use lowercase kebab-case route segments.
- Use plural nouns for collections, such as `/api/v1/songs`.
- Do not expose local filesystem paths, private media keys, or personal singer data in public URLs.

## Database tables

When database work begins in later waves:

- Use lowercase snake_case table and column names.
- Use plural table names for collections, such as `songs` and `host_devices`.
- Use `_id` suffixes for foreign keys.
- Prefer `created_at`, `updated_at`, and explicit soft-retirement timestamps over ambiguous status-only fields.

## UI routes

When UI work begins in later waves:

- Use lowercase kebab-case route segments.
- Keep staff/admin routes separate from guest request routes.
- Do not put secrets, access tokens, private URLs, or personal singer details in route paths.

## Batch policy

Wave 1A creates read-only HQ catalog endpoints only. It does not create host features, playback, syncing, mobile requests, OBS integration, Replay integration, admin write APIs, or external-source acquisition workflows.
