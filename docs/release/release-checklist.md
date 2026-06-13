# Release Checklist Template

Use this checklist before tagging any release or pilot build.

## Scope

- [ ] Release name and version are selected.
- [ ] Completed backlog tasks are marked in `docs/MASTER-BACKLOG-577.md`.
- [ ] Deferred work is documented with clear labels and follow-up issues.
- [ ] Known limitations are updated.

## Validation

- [ ] Repo-wide smoke test passes.
- [ ] Service-specific tests pass for changed components.
- [ ] Demo fixtures only are included in the repository.
- [ ] No secrets, real media, private URLs, or personal singer information are present.
- [ ] Local-first show behavior is preserved for any live-show-facing changes.

## Backup and rollback

- [ ] Backup steps are documented for any data-changing release.
- [ ] Rollback steps are documented and tested where practical.
- [ ] Any migration has a review-first or preview step before destructive changes.

## Communication

- [ ] Operator-facing release notes are written in plain language.
- [ ] Setup or upgrade steps are documented.
- [ ] Remaining limitations and decisions are called out.
