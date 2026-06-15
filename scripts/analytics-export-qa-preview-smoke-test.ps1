
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/analytics-export-qa-preview-shell.md',
  'analytics/demo-data/analytics-export-qa-fixtures.json',
  'analytics/src/analytics-export-qa-preview.html'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing analytics export QA preview shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'analytics/demo-data/analytics-export-qa-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'exportsCsv',
  'generatesAnalytics',
  'startsServer',
  'stopsServer',
  'changesInternet',
  'changesRouter',
  'writesRequestDatabase',
  'interruptsSync',
  'calculatesRealChecksums',
  'makesNetworkRequests',
  'writesFiles'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Analytics export QA preview guard must remain false: $guard"
  }
}

$html = Get-Content -LiteralPath (Join-Path $root 'analytics/src/analytics-export-qa-preview.html') -Raw
foreach ($requiredPhrase in @(
  'CSV analytics export',
  'Analytics empty states',
  'Analytics tests',
  'Server-unavailable test scenario',
  'Venue-internet-loss test scenario',
  'Local-router-only request test scenario',
  'Interrupted-sync test scenario',
  'Checksum-mismatch test scenario',
  'No real CSV export',
  'No analytics generation',
  'No server start or stop',
  'No internet or router changes',
  'No request database writes',
  'No sync interruption',
  'No checksum calculation against real files',
  'No network request',
  'No filesystem writes beyond fixtures'
)) {
  if ($html -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Analytics export QA preview shell is missing Wave 13B phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/analytics-export-qa-preview-shell.md') -Raw
foreach ($requiredPhrase in @(
  'Wave 13B adds',
  'CSV analytics export preview',
  'analytics empty states preview',
  'analytics tests preview',
  'server-unavailable test scenario preview',
  'venue-internet-loss test scenario preview',
  'local-router-only request test scenario preview',
  'interrupted-sync test scenario preview',
  'checksum-mismatch test scenario preview'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Analytics export QA preview doc is missing Wave 13B phrase: $requiredPhrase"
  }
}

Write-Host 'Analytics export QA preview smoke test passed: CSV export, empty states, analytics tests, server unavailable, internet loss, local-router-only request, interrupted sync, checksum mismatch, and safety markers are present.'
