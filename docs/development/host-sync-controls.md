# Host Sync Controls

Wave 2B starts the safe synchronization control layer for host devices.

This document covers planning contracts only. It does not add real media download, file transfer, cleanup deletion, karaoke playback, Windows UI, mobile request screens, OBS integration, Replay integration, or external acquisition workflows.

## Goals

Wave 2B control/status work is meant to describe and validate:

- sync progress reporting from host to HQ
- sync error reporting from host to HQ
- pause, resume, and cancel intent controls
- storage capacity checks before any future sync execution
- checksum verification result reporting
- quarantine metadata for failed verification
- interrupted-operation resume metadata
- retry limits and backoff planning
- operator-facing sync summaries
- action placeholders for Sync Now, Verify Library, View Missing Locally, and Review Cleanup Candidates

## Status states

Allowed high-level sync states are:

- `ready`
- `pending`
- `syncing`
- `verified`
- `failed`
- `review_needed`
- `paused`
- `cancelled`

These states are for UI/API planning only in this chunk.

## Operator actions

Allowed operator action placeholders are:

- `sync_now`
- `verify_library`
- `view_missing_locally`
- `review_cleanup_candidates`
- `pause_sync`
- `resume_sync`
- `cancel_pending_noncritical`

Actions are intentionally limited to `plan_only` or `metadata_only` safety modes until later waves add real execution.

## Safety boundaries

The sync control layer must not make HQ a live-show dependency.

The host app remains responsible for live-show operation. HQ may plan, summarize, and receive status updates, but live playback must remain local-first and offline-safe.

No response or contract should expose private filesystem paths, secrets, credentials, venue network details, or real karaoke media.

## Contracts

- `packages/contracts/schemas/sync-control-state.v1.schema.json`
- `packages/contracts/schemas/sync-operator-action.v1.schema.json`

## Later implementation notes

Later sub-waves may add database persistence, repository methods, and HTTP endpoints for these contracts. This first manual chunk only adds the shared shape and documentation so the next code changes stay smaller and easier to review.
