# Feature-Flag Conventions

Feature flags keep unfinished or optional modules controlled while the product is built in waves.

## Naming

Use lowercase dotted names in documentation and typed code:

```text
<component>.<feature>[.<variant>]
```

Examples:

- `host.demo-mode`
- `server.catalog-search`
- `request-web.kiosk-mode`
- `integrations.obs-companion`
- `integrations.replay-export`

Environment variable names should use uppercase snake case with a `DJK_FEATURE_` prefix, such as `DJK_FEATURE_HOST_DEMO_MODE`.

## Defaults

- Unfinished production behavior defaults to off.
- Demo-only placeholders may default to on only inside demo mode.
- Optional integrations must fail closed and must not interrupt a live show.
- Flags must never contain secrets, private URLs, media paths, or personal singer information.

## Documentation

Every non-temporary flag should document:

- Purpose and owning component.
- Default value by environment.
- Whether it is safe during an active show.
- Removal criteria.

## Wave 0A decisions

This PR defines conventions only. It does not add flag evaluation code or enable any host, server, request-web, playback, sync, OBS, or Replay behavior.
