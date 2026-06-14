# Changelog

All notable changes to D & J's Karaoke Software will be documented here.

This project follows a review-first changelog style. Add entries under `Unreleased` as pull requests land, then move them into a dated release section during release preparation.

## Unreleased

### Added

- Repository foundation documentation and placeholder structure for Wave 0A.
- Wave 0B architecture documents, shared JSON Schema contracts, local development scaffolding, CI workflow, and safety guardrail scripts.
- Wave 1A HQ catalog foundation with PostgreSQL-backed read-only endpoints, repeat-safe migrations and seed data, safe demo catalog metadata, and live PostgreSQL CI coverage.
- Wave 1B HQ catalog controls with alternate-version reads, temporary protected admin write routes, deterministic normalization, safe error envelopes, search rate limiting, structured audit history, reset/reseed tooling, migration rollback docs, and expanded PostgreSQL CI coverage.
- Wave 2A host registration and sync manifest foundation with fail-closed development host tokens, host heartbeat state, redacted admin host-status summaries, deterministic manifest planning, manifest diffs, review-first cleanup candidates, sync flags, priority inputs, interrupted-sync tracking, docs, and tests.

### Changed

- Repository status and developer documentation now describe Wave 2A host sync planning checks, protected setup, and local-first safety boundaries.

### Fixed

- Nothing yet.

### Security

- Nothing yet.
