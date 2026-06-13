# Contributing

Thanks for helping with D & J's Karaoke Software. This repository is currently in foundation mode, so pull requests should stay small, trace back to `docs/MASTER-BACKLOG-577.md`, and preserve the local-first live-show boundary.

## Working rules

- Complete backlog tasks in dependency order using `docs/CODEX-EXECUTION-WAVES.md`.
- Keep each pull request focused on one task or a tightly related small group.
- Update the master backlog checkbox when the work is complete.
- Use demo fixtures and placeholders only.
- Do not commit real karaoke files, credentials, private URLs, venue network details, or personal singer information.
- Do not add arbitrary ripping or unattended download workflows.

## Before opening a pull request

1. Run the repo-wide smoke test from the repository root:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\smoke-test.ps1
   ```

   PowerShell 7 (`pwsh`) can run the same script if it is installed.

2. Confirm the changed files match the issue scope.
3. Document validation results and any deferred decisions in the pull request body.

Additional focused checks are available when a change touches a narrower area:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-format.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\lint-web.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-contracts.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-secrets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-media-files.ps1
```

## Pull request notes

Use clear, operator-safe wording. If a task introduces behavior that could affect a live show, document the fallback and rollback expectations before asking for review.
