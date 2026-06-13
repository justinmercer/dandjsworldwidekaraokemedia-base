# Quality Gates

Wave 0B adds automated guardrails that can run locally and in CI.

## Local checks

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\smoke-test.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-format.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\lint-web.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-test.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\dependency-audit.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-secrets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-media-files.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-env-secrets.ps1
```

## CI

`.github/workflows/ci.yml` runs the same foundation checks on pull requests and pushes.

## Decisions still needed

- Final formatter and linter packages once .NET and web projects exist.
- Final vulnerability scanning provider if GitHub Advanced Security or another service is enabled.
- Final generated-client strategy for shared contracts.

## Wave 0B limitation

The checks validate repository safety and placeholder contracts. They do not build product features that have not been created yet.
