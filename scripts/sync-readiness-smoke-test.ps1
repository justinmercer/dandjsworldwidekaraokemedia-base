
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/host-sync-foundation.md',
  'docs/development/host-sync-controls.md',
  'docs/development/host-sync-readiness.md',
  'packages/contracts/schemas/synchronization-manifest.v1.schema.json',
  'packages/contracts/schemas/sync-control-state.v1.schema.json',
  'packages/contracts/schemas/sync-operator-action.v1.schema.json',
  'server/hq/src/hostSync.js',
  'server/hq/src/catalogRepository.js',
  'server/hq/src/postgresCatalogRepository.js',
  'server/hq/src/httpServer.js',
  'server/hq/database/migrations/0003_host_sync_foundation.sql',
  'server/hq/database/migrations/0004_sync_control_persistence.sql',
  'server/hq/test/catalogRepository.test.js',
  'server/hq/test/httpServer.test.js',
  'server/hq/test/hostSync.test.js',
  'server/hq/test/postgresIntegration.test.js'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing sync-readiness file: $path"
  }
}

$backlogPath = Join-Path $root 'docs/MASTER-BACKLOG-577.md'
$backlog = Get-Content -LiteralPath $backlogPath -Raw

foreach ($taskNumber in 1..160) {
  $taskId = 'KARA-{0:D3}' -f $taskNumber
  if ($backlog -notmatch "- \[x\] ``$taskId``") {
    throw "Backlog task $taskId is not marked complete."
  }
}

foreach ($taskNumber in 161..577) {
  $taskId = 'KARA-{0:D3}' -f $taskNumber
  if ($backlog -match "- \[x\] ``$taskId``") {
    throw "Backlog task $taskId should remain unchecked after Wave 2."
  }
}

$hostSyncDoc = Get-Content -LiteralPath (Join-Path $root 'docs/development/host-sync-readiness.md') -Raw
foreach ($requiredPhrase in @('planning-only', 'metadata-only', 'must not', 'download media', 'delete media', 'local-first', 'Sync Now', 'Verify Library', 'Review Cleanup Candidates')) {
  if ($hostSyncDoc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Host sync readiness doc is missing required phrase: $requiredPhrase"
  }
}

& (Join-Path $PSScriptRoot 'check-media-files.ps1')
& (Join-Path $PSScriptRoot 'check-env-secrets.ps1')
& (Join-Path $PSScriptRoot 'check-secrets.ps1')

Write-Host "Sync-readiness smoke test passed: required files present, KARA-001..160 checked, KARA-161..577 unchecked, and safety guardrails passed."
