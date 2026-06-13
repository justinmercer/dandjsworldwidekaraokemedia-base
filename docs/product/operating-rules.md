# Operating Rules

These rules are non-negotiable product boundaries for future implementation work.

## Local-first live-show rule

An active show must keep running if internet access, the HQ server, a request web app, OBS companion, Replay adapter, or any optional cloud service is unavailable.

Future host-app work must therefore:

- Keep playback and show controls local to the host laptop.
- Treat network services as helpful but optional during a show.
- Queue or defer noncritical work instead of blocking the operator.
- Make offline, local-only, and online states visible to staff.
- Avoid forced updates, destructive cleanup, or blocking sync during a live show.

## Authorized-media-only rule

The product may store, index, or synchronize only karaoke media that the operator owns or is otherwise authorized to use.

Future catalog and import work must therefore:

- Keep authorization notes and source records where appropriate.
- Avoid public exposure of local filesystem paths or private media keys.
- Use review-first behavior before cleanup, import, merge, or retirement actions.
- Never commit real karaoke files to this repository.

## Safe YouTube-preview-only rule

YouTube support is limited to official search and embedded preview review for missing-song workflows.

Future YouTube work must therefore:

- Use official APIs and embedded previews only.
- Avoid arbitrary ripping, unattended downloading, or bypass workflows.
- Keep preview review host-controlled.
- Clearly separate a preview candidate from an authorized local copy.
- Respect quota, caching, and disablement behavior.

## Wave 0A limitation

This document defines rules only. It does not add APIs, playback, import, sync, mobile request, OBS companion, or Replay implementation.
