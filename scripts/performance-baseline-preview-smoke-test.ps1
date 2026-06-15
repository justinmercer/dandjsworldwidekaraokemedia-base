
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/performance-baseline-preview-shell.md',
  'qa/demo-data/performance-baseline-preview-fixtures.json',
  'qa/src/performance-baseline-preview.html'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing performance baseline preview shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'qa/demo-data/performance-baseline-preview-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'runsPerformanceTest',
  'generatesLoad',
  'runsSoakLoop',
  'probesCpu',
  'probesMemory',
  'readsCatalogDatabase',
  'writesRequestDatabase',
  'makesNetworkRequests',
  'writesFiles'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Performance baseline preview guard must remain false: $guard"
  }
}

$html = Get-Content -LiteralPath (Join-Path $root 'qa/src/performance-baseline-preview.html') -Raw
foreach ($requiredPhrase in @(
  'Large-catalog search performance test',
  'High-request-volume test',
  'Multi-hour soak test',
  'Host CPU and memory baseline measurements',
  'No real performance test',
  'No load generation',
  'No soak loop',
  'No CPU probing',
  'No memory probing',
  'No catalog database reads',
  'No request database writes',
  'No network request',
  'No filesystem writes beyond fixtures'
)) {
  if ($html -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Performance baseline preview shell is missing Wave 13D phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/performance-baseline-preview-shell.md') -Raw
foreach ($requiredPhrase in @(
  'Wave 13D adds',
  'large-catalog search performance test preview',
  'high-request-volume test preview',
  'multi-hour soak test preview',
  'host CPU and memory baseline measurements preview'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Performance baseline preview doc is missing Wave 13D phrase: $requiredPhrase"
  }
}

Write-Host 'Performance baseline preview smoke test passed: large catalog search, high request volume, multi-hour soak, host CPU/memory baseline, and safety markers are present.'
