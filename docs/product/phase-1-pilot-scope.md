# Phase 1 Pilot Scope

Phase 1 is the first pilot-show product slice. It should prove that D & J's can run a safe local-first show workflow before optional integrations or productization work begins.

## Pilot goals

- Keep a live show operational from the host laptop even without internet.
- Work only with operator-owned or otherwise authorized karaoke media.
- Give staff clear visibility into catalog, rotation, requests, and sync state as those features arrive in later waves.
- Use demo and test fixtures until real operator data is intentionally imported outside source control.
- Preserve rollback-safe and backup-first behavior for imports, cleanup, updates, and restores.

## In scope for Phase 1 planning

- Windows host application foundation.
- Local catalog and show-state persistence.
- Authorized catalog import and review workflows.
- Singer rotation and show-session recovery.
- Local playback and external display workflows.
- Request intake after the host and server contracts are ready.
- HQ catalog and synchronization only when they do not threaten active-show operation.
- Operator documentation, diagnostics, and pilot readiness checks.

## Explicitly deferred from Wave 0A

The following are not implemented in this PR:

- Server APIs and database migrations.
- Windows host application features.
- Playback, audio, preview, and external-display behavior.
- Synchronization or host registration.
- Mobile request web app behavior.
- OBS companion integration.
- Replay integration.
- Production licensing enforcement, billing, reseller, or hosted-product workflows.
- Real media imports, private URLs, secrets, or personal singer information.

## Decisions still needed

- Final UI framework for the Windows host.
- Final playback engine.
- Final deployment topology for the HQ server.
- Final licensing model.
- Final pilot venue network and hardware checklist.
