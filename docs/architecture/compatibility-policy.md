# Host Compatibility Policy

Older host-app versions must be protected because they may be used during live shows and may operate offline.

## Policy

- A host app must be able to finish an active show with its local data even if HQ contracts or request-web behavior have advanced.
- HQ server changes must tolerate at least the currently supported host contract version during a pilot overlap period.
- Contract additions should default safely when an older host does not send or understand a field.
- Server-side requirements that would block an older host must be treated as breaking changes and require an ADR.
- Optional integrations, including OBS and Replay, must fail closed and must not interrupt playback or show management.

## Deprecation process

1. Document the new contract version and the oldest supported host version.
2. Keep compatibility checks in CI during the overlap window.
3. Provide operator-facing upgrade guidance before removing support.
4. Do not force upgrades during an active show.

## Wave 1A limitation

This policy is planning only. There is no host binary, update mechanism, production API, synchronization job, OBS adapter, or Replay adapter in this wave.
