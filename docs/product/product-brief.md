# Product Brief

## Product vision

D & J's Karaoke Software is a local-first system for running karaoke shows with confidence. The host should be able to manage the show, singers, requests, and authorized catalog information without relying on internet access during an active performance.

## Primary users

- Karaoke host/operator running a live show.
- Staff helping manage requests or rotation.
- Guests submitting song requests through future approved request channels.
- Owner/admin maintaining authorized catalog and venue settings.

## Components

### Windows host app

The host app is the live-show control center. It will eventually own playback, rotation, local show state, local catalog cache, diagnostics, and operator-facing controls. It must continue operating during internet, server, OBS companion, Replay, or request-web outages.

### Request web app

The request web app is a future guest-facing surface for searching the approved catalog and submitting requests. It must use privacy-safe defaults and must not become a dependency for active playback.

### HQ server

The HQ server is a future administrative and synchronization layer for authorized catalog metadata, host devices, request coordination, backups, and reporting. It must support, not replace, local-first show operation.

### Replay boundary

Replay integration is future optional work. The initial boundary is event-oriented: the host may later publish approved performance metadata to an adapter, but Replay failures must not interrupt playback or show management. This PR adds no Replay adapter or event code.

### Future licensing direction

The licensing model is undecided. The product may remain private, become source-available, or support future branded, reseller, or hosted editions. The license placeholder records that decision as pending before public or partner distribution.

## Non-goals for Wave 0A

Wave 0A does not implement server APIs, host app behavior, playback, synchronization, mobile request workflows, OBS companion features, Replay features, real media handling, or licensing enforcement.
