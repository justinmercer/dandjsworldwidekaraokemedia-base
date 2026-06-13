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
  'host/README.md',
  'host/.env.example',
  'server/README.md',
  'server/.env.example',
  'apps/request-web/README.md',
  'apps/request-web/.env.example',
  'packages/contracts/README.md',
  'infra/README.md',
  'tests/README.md'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing required foundation file: $path"
  }
}

$backlogPath = Join-Path $root 'docs/MASTER-BACKLOG-577.md'
$backlog = Get-Content -LiteralPath $backlogPath -Raw
foreach ($taskNumber in 1..25) {
  $taskId = 'KARA-{0:D3}' -f $taskNumber
  if ($backlog -notmatch "- \[x\] ``$taskId``") {
    throw "Backlog task $taskId is not marked complete."
  }
}

if ($backlog -notmatch '- \[ \] `KARA-026`') {
  throw 'KARA-026 should remain unchecked for Wave 0A.'
}

$allFiles = Get-ChildItem -LiteralPath $root -Recurse -File -Force |
  Where-Object { $_.FullName -notmatch '\\.git(\\|$)' }

$forbiddenExtensions = @('.cdg', '.kar', '.mid', '.midi', '.mp3', '.mp4', '.mkv', '.mov', '.avi', '.wav', '.flac', '.db', '.sqlite', '.sqlite3', '.dump', '.bak', '.backup')
$forbiddenFiles = $allFiles | Where-Object { $forbiddenExtensions -contains $_.Extension.ToLowerInvariant() }
if ($forbiddenFiles) {
  $names = ($forbiddenFiles | ForEach-Object { $_.FullName.Substring($root.Length + 1) }) -join ', '
  throw "Forbidden media, database, or backup files found: $names"
}

$nonExampleEnvFiles = $allFiles | Where-Object {
  $_.Name -like '.env*' -and $_.Name -ne '.env.example' -and $_.Name -notlike '*.env.example'
}
if ($nonExampleEnvFiles) {
  $names = ($nonExampleEnvFiles | ForEach-Object { $_.FullName.Substring($root.Length + 1) }) -join ', '
  throw "Non-example environment files found: $names"
}

Write-Host "Wave 0A smoke checks passed: $($requiredFiles.Count) required files present, KARA-001..025 checked, no forbidden media/secrets placeholders found."
