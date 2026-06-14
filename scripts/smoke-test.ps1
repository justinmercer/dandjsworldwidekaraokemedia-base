$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'README.md',
  '.gitignore',
  '.env.example',
  '.editorconfig',
  '.gitattributes',
  'LICENSE.md',
  'CHANGELOG.md',
  'CONTRIBUTING.md',
  'SECURITY.md',
  '.github/CODEOWNERS',
  'docs/README.md',
  'docs/product/product-brief.md',
  'docs/product/phase-1-pilot-scope.md',
  'docs/product/supported-platforms.md',
  'docs/product/hardware-profiles.md',
  'docs/product/operating-rules.md',
  'docs/adr/0000-template.md',
  'docs/release/release-checklist.md',
  'docs/process/issue-labels.md',
  'docs/architecture/naming-conventions.md',
  'docs/architecture/feature-flags.md',
  'docs/architecture/system-context.md',
  'docs/architecture/service-boundaries.md',
  'docs/architecture/shared-contracts.md',
  'docs/architecture/contract-versioning.md',
  'docs/architecture/compatibility-policy.md',
  'docs/architecture/observability-and-service-health.md',
  'docs/development/local-stack.md',
  'docs/development/hq-api-only.md',
  'docs/development/request-web-only.md',
  'docs/development/windows-host-cli-build.md',
  'docs/development/quality-gates.md',
  'host/README.md',
  'host/.env.example',
  'server/README.md',
  'server/.env.example',
  'apps/request-web/README.md',
  'apps/request-web/.env.example',
  'apps/request-web/dev-proxy.config.json',
  'packages/contracts/README.md',
  'packages/contracts/VERSION.md',
  'packages/contracts/schemas/song-metadata.v1.schema.json',
  'packages/contracts/schemas/singer-profile.v1.schema.json',
  'packages/contracts/schemas/venue-profile.v1.schema.json',
  'packages/contracts/schemas/show-session.v1.schema.json',
  'packages/contracts/schemas/song-request.v1.schema.json',
  'packages/contracts/schemas/host-device.v1.schema.json',
  'packages/contracts/schemas/synchronization-manifest.v1.schema.json',
  'packages/contracts/schemas/playback-state.v1.schema.json',
  'packages/contracts/schemas/external-display-state.v1.schema.json',
  'packages/contracts/schemas/obs-companion-event.v1.schema.json',
  'packages/contracts/schemas/replay-event.v1.schema.json',
  'packages/contracts/schemas/api-request-context.v1.schema.json',
  'packages/contracts/schemas/service-health.v1.schema.json',
  'packages/contracts/schemas/service-readiness.v1.schema.json',
  'packages/contracts/schemas/sync-control-state.v1.schema.json',
  'packages/contracts/schemas/sync-operator-action.v1.schema.json',
  'infra/README.md',
  'infra/local/docker-compose.yml',
  'infra/local/observability/logging.config.json',
  'tests/README.md',
  'tests/fixtures/demo-seed/README.md',
  'tests/fixtures/demo-seed/songs.demo.json',
  'tests/fixtures/demo-seed/singers.demo.json',
  '.github/workflows/ci.yml',
  'scripts/check-format.ps1',
  'scripts/lint-web.ps1',
  'scripts/build-test.ps1',
  'scripts/dependency-audit.ps1',
  'scripts/check-secrets.ps1',
  'scripts/check-media-files.ps1',
  'scripts/check-env-secrets.ps1',
  'scripts/validate-contracts.ps1',
  'scripts/validate-hq-catalog.ps1',
  'scripts/validate-docker-compose.ps1',
  'scripts/check-hq-postgres-integration.ps1',
  'scripts/run-hq-migrations.ps1',
  'scripts/reset-hq-catalog.ps1',
  'scripts/reseed-hq-catalog.ps1',
  'scripts/start-local-stack.ps1',
  'scripts/stop-local-stack.ps1',
  'scripts/reset-local-stack.ps1',
  'scripts/inspect-local-stack.ps1',
  'scripts/load-demo-seed.ps1',
  'server/hq/package.json',
  'server/hq/src/normalization.js',
  'server/hq/src/catalogData.js',
  'server/hq/src/hostSync.js',
  'server/hq/src/catalogRepository.js',
  'server/hq/src/postgresCatalogRepository.js',
  'server/hq/src/repositoryFactory.js',
  'server/hq/src/httpServer.js',
  'server/hq/src/index.js',
  'server/hq/test/catalogRepository.test.js',
  'server/hq/test/httpServer.test.js',
  'server/hq/test/postgresIntegration.test.js',
  'server/hq/test/repositoryFactory.test.js',
  'server/hq/data/demo-catalog.json',
  'server/hq/package-lock.json',
  'server/hq/database/migrations/0001_authorized_catalog.sql',
  'server/hq/database/migrations/0002_catalog_controls.sql',
  'server/hq/database/migrations/0003_host_sync_foundation.sql',
  'server/hq/database/migrations/0004_sync_control_persistence.sql',
  'server/hq/database/seeds/0001_demo_catalog.sql',
  'docs/development/catalog-api.md',
  'docs/development/host-sync-foundation.md',
  'docs/development/host-sync-controls.md',
  'docs/development/storage-mounts.md',
  'docs/development/migration-rollback.md'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing required foundation file: $path"
  }
}

$backlogPath = Join-Path $root 'docs/MASTER-BACKLOG-577.md'
$backlog = Get-Content -LiteralPath $backlogPath -Raw
foreach ($taskNumber in 1..151) {
  $taskId = 'KARA-{0:D3}' -f $taskNumber
  if ($backlog -notmatch "- \[x\] ``$taskId``") {
    throw "Backlog task $taskId is not marked complete."
  }
}

foreach ($taskNumber in 152..577) {
  $taskId = 'KARA-{0:D3}' -f $taskNumber
  if ($backlog -match "- \[x\] ``$taskId``") {
    throw "Backlog task $taskId should remain unchecked after Wave 2B planning controls."
  }
}

& (Join-Path $PSScriptRoot 'validate-contracts.ps1')
& (Join-Path $PSScriptRoot 'validate-hq-catalog.ps1')
& (Join-Path $PSScriptRoot 'validate-docker-compose.ps1')
& (Join-Path $PSScriptRoot 'check-media-files.ps1')
& (Join-Path $PSScriptRoot 'check-env-secrets.ps1')
& (Join-Path $PSScriptRoot 'check-secrets.ps1')

Write-Host "Wave 2B smoke checks passed: $($requiredFiles.Count) required files present, KARA-001..151 checked, KARA-152..577 unchecked, and safety guardrails passed."
