# D & J’s Karaoke Software — Codex Execution Waves

Use this document with `docs/MASTER-BACKLOG-577.md`. Codex should complete focused pull requests in dependency order, mark completed checkboxes in the master backlog, and avoid combining unrelated work into large changes.

## Rules for every wave

- Add or update tests for changed behavior.
- Keep production integrations optional until pilot checks pass.
- Use demo fixtures only.
- Preserve local-first playback and failure isolation.
- Do not add arbitrary YouTube ripping or unattended download behavior.
- Update documentation and known limitations.

## Wave 0 — Ground rules and scaffolding

**Tasks:** `KARA-001–060`

Repository foundation, architecture, contracts, local development, CI, and safety checks. Complete before feature work.

## Wave 1 — HQ catalog core

**Tasks:** `KARA-061–110`

Build the authorized catalog database, search, admin APIs, audit history, and documentation.

## Wave 2 — Host registration and synchronization planning

**Tasks:** `KARA-111–160`

Register host laptops, generate deterministic manifests, report progress, verify integrity, and expose operator controls.

## Wave 3 — Windows host shell

**Tasks:** `KARA-161–210`

Create the desktop application shell, local persistence, settings, diagnostics, and demo mode.

## Wave 4 — Import and Siglos migration

**Tasks:** `KARA-211–250`

Add local import review and Siglos export migration with backup-first behavior.

## Wave 5 — Singer rotation and show recovery

**Tasks:** `KARA-251–290`

Build singer profiles, queues, fair rotation, autosave, and recovery.

## Wave 6 — Playback and displays

**Tasks:** `KARA-291–335`

Add local playback controls, output settings, external display windows, themes, and troubleshooting.

## Wave 7 — Mobile requests and kiosk

**Tasks:** `KARA-336–381`

Build the QR request web app, local-network mode, PWA shell, and shared-tablet mode.

## Wave 8 — Moderation and safe missing-song review

**Tasks:** `KARA-382–422`

Connect requests to the host, add moderation, and implement official YouTube search-and-preview only.

## Wave 9 — Venue profiles

**Tasks:** `KARA-423–447`

Add venue settings, themes, QR materials, announcements, and onboarding docs.

## Wave 10 — OBS and Replay boundaries

**Tasks:** `KARA-448–472`

Add optional, failure-isolated companion exports and mock Replay adapters.

## Wave 11 — Admin and privacy

**Tasks:** `KARA-473–497`

Add staff roles, first-login password change, route protection, privacy, retention, and security checks.

## Wave 12 — Backup, installer, and updates

**Tasks:** `KARA-498–527`

Add backup, restore, diagnostics, Windows packaging, postponable updates, and rollback.

## Wave 13 — QA and pilot readiness

**Tasks:** `KARA-528–577`

Add analytics, fault injection, load tests, soak tests, operator guides, pilot checklists, and future roadmap notes.

## Pilot release boundary

The first pilot can proceed only after the required subsets of Waves 0–13 are completed and the pilot-show checklist passes. Deferred future-product notes may remain unchecked when they are clearly labeled as deferred.