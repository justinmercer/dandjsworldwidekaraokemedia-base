
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/phase2-future-notes-shell.md',
  'docs/future/phase-2-backlog.md',
  'docs/future/licensing-model-placeholder.md',
  'docs/future/multi-tenant-architecture-notes.md',
  'docs/future/branded-reseller-notes.md',
  'docs/future/cloud-hosting-cost-notes.md',
  'docs/future/mobile-app-decision-record.md',
  'docs/future/face-matching-privacy-consent-research-note.md',
  'qa/demo-data/phase2-future-notes-fixtures.json',
  'qa/src/phase2-future-notes-preview.html'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing Phase 2 future notes shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'qa/demo-data/phase2-future-notes-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'makesLicensingDecision',
  'makesPricingCommitment',
  'provisionsCloud',
  'buildsMobileApp',
  'implementsFaceRecognition',
  'processesBiometrics',
  'changesMultiTenantRuntime',
  'automatesBrandedReseller',
  'makesNetworkRequests',
  'readsDatabase',
  'writesDatabase',
  'writesRuntimeFiles'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Phase 2 future notes guard must remain false: $guard"
  }
}

$html = Get-Content -LiteralPath (Join-Path $root 'qa/src/phase2-future-notes-preview.html') -Raw
foreach ($requiredPhrase in @(
  'Phase 2 backlog document',
  'Future licensing model placeholder',
  'Future multi-tenant architecture notes',
  'Future branded-reseller notes',
  'Future cloud-hosting cost notes',
  'Future mobile-app decision record',
  'Future face-matching privacy and consent research note',
  'No licensing decisions',
  'No pricing commitments',
  'No cloud provisioning',
  'No mobile app build',
  'No face recognition implementation',
  'No biometric processing',
  'No multi-tenant runtime changes',
  'No branded reseller automation',
  'No network request',
  'No database reads or writes',
  'No filesystem writes beyond docs and fixtures'
)) {
  if ($html -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Phase 2 future notes preview shell is missing Wave 14C phrase: $requiredPhrase"
  }
}

$research = Get-Content -LiteralPath (Join-Path $root 'docs/future/face-matching-privacy-consent-research-note.md') -Raw
foreach ($requiredPhrase in @(
  'No face recognition',
  'biometric processing',
  'camera access',
  'photo analysis',
  'identity matching',
  'data collection'
)) {
  if ($research -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Face-matching research note is missing privacy boundary phrase: $requiredPhrase"
  }
}

Write-Host 'Phase 2 future notes smoke test passed: Phase 2 backlog, licensing, multi-tenant, reseller, cloud cost, mobile decision, face-matching privacy research, and safety markers are present.'
