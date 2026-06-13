# Naming Conventions

Use consistent names so later services, contracts, routes, and tables are easy to review.

## Services and packages

- `host-app`: Windows host application.
- `hq-server`: server-side administration, catalog, sync, and request APIs when they are implemented.
- `request-web`: guest request web app.
- `shared-contracts`: cross-component DTOs, schemas, and versioned API contracts.
- `infra`: local development and deployment support files.

Use kebab case for service and package folder names.

## Endpoints

When server APIs begin in a later wave:

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

## Placeholder policy

Wave 0A names are documentation commitments only. They do not create server APIs, host features, playback, syncing, mobile requests, OBS integration, or Replay integration.
