# Issue Label Conventions

Labels should make backlog scope, release risk, and review state clear without exposing private show or singer details.

## Type labels

- `type:feature` - planned product capability.
- `type:bug` - incorrect behavior or regression.
- `type:docs` - documentation-only work.
- `type:qa` - test, validation, or readiness work.
- `type:chore` - repository maintenance.

## Scope labels

- `scope:foundation`
- `scope:host-app`
- `scope:hq-server`
- `scope:request-web`
- `scope:shared-contracts`
- `scope:infra`
- `scope:operator-docs`
- `scope:integration-boundary`

## Status labels

- `status:ready-for-codex`
- `status:in-progress`
- `status:blocked`
- `status:needs-decision`
- `status:deferred`
- `status:review-needed`

## Risk and release labels

- `risk:live-show`
- `risk:data-privacy`
- `risk:media-authorization`
- `priority:release-blocker`
- `priority:pilot-required`
- `priority:future`

## Codex wave labels

Use wave labels to keep pull requests dependency-ordered:

- `codex:wave-0`
- `codex:wave-1`
- `codex:wave-2`
- `codex:wave-3`
- `codex:wave-4`
- `codex:wave-5`
- `codex:wave-6`
- `codex:wave-7`
- `codex:wave-8`
- `codex:wave-9`
- `codex:wave-10`
- `codex:wave-11`
- `codex:wave-12`
- `codex:wave-13`

## Deferred work

Use `status:deferred` plus the relevant `codex:wave-*` and `scope:*` labels when a feature is intentionally out of the current PR. Do not use labels to hide incomplete acceptance criteria inside a supposedly complete task.
