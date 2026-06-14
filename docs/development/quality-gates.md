# Quality Gates

Wave 1B keeps the foundation guardrails and adds HQ catalog controls validation.

## Local checks

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\smoke-test.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-format.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\lint-web.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-test.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-hq-catalog.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-docker-compose.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-hq-postgres-integration.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\dependency-audit.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-secrets.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-media-files.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-env-secrets.ps1
```

## CI

`.github/workflows/ci.yml` runs the same foundation checks on pull requests and pushes. It also validates Docker Compose syntax and runs a live PostgreSQL-backed HQ catalog integration check.

## Decisions still needed

- Final formatter and linter packages once .NET and web projects expand.
- Final vulnerability scanning provider if GitHub Advanced Security or another service is enabled.
- Final generated-client strategy for shared contracts.

## Wave 1B limitation

The checks validate repository safety, shared contracts, the HQ catalog migration shape, public catalog reads, protected catalog-management routes, audit history, and the database-backed catalog API. They do not validate playback, syncing, request screens, OBS, Replay, full staff authentication, or external-source acquisition workflows.
