
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/update-release-preview-shell.md',
  'maintenance/demo-data/update-release-preview-fixtures.json',
  'maintenance/src/update-release-preview.html'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing update release preview shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'maintenance/demo-data/update-release-preview-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'runsUpdate',
  'performsBackup',
  'performsRollback',
  'runsUninstall',
  'buildsInstaller',
  'buildsPackage',
  'deletesFiles',
  'makesNetworkRequests',
  'writesFiles'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Update release preview guard must remain false: $guard"
  }
}

$html = Get-Content -LiteralPath (Join-Path $root 'maintenance/src/update-release-preview.html') -Raw
foreach ($requiredPhrase in @(
  'Backup-before-update behavior',
  'Rollback-safe update behavior',
  'Update-failure messaging',
  'Uninstall behavior documentation',
  'Clean-install smoke tests',
  'Upgrade smoke tests',
  'Rollback smoke tests',
  'Release packaging',
  'No real update',
  'No backup',
  'No rollback',
  'No uninstall',
  'No installer build',
  'No packaging build',
  'No file deletion',
  'No network request',
  'No filesystem writes beyond fixtures'
)) {
  if ($html -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Update release preview shell is missing Wave 12D phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/update-release-preview-shell.md') -Raw
foreach ($requiredPhrase in @(
  'Wave 12D adds',
  'backup-before-update behavior preview',
  'rollback-safe update behavior preview',
  'update-failure messaging preview',
  'uninstall behavior documentation preview',
  'clean-install smoke tests preview',
  'upgrade smoke tests preview',
  'rollback smoke tests preview',
  'release packaging documentation preview'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Update release preview doc is missing Wave 12D phrase: $requiredPhrase"
  }
}

Write-Host 'Update release preview smoke test passed: backup-before-update, rollback-safe update, failure messaging, uninstall docs, clean install, upgrade, rollback, release packaging, and safety markers are present.'
