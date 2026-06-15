
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/load-readiness-operator-shell.md',
  'docs/operations/pilot-show-go-no-go-checklist.md',
  'docs/operations/pre-show-checklist.md',
  'docs/operations/post-show-checklist.md',
  'docs/operations/known-limitations.md',
  'docs/operations/operator-quick-start-guide.md',
  'qa/demo-data/load-readiness-operator-fixtures.json',
  'qa/src/load-readiness-operator-preview.html',
  'scripts/hq-api-load-test-preview.ps1',
  'scripts/request-web-load-test-preview.ps1'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing load readiness operator shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'qa/demo-data/load-readiness-operator-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'runsLoadTests',
  'callsHqApi',
  'callsRequestWeb',
  'generatesReadinessReportFile',
  'probesServer',
  'changesRouter',
  'readsDatabase',
  'writesDatabase',
  'makesNetworkRequests',
  'writesRuntimeFiles'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Load readiness operator guard must remain false: $guard"
  }
}

$html = Get-Content -LiteralPath (Join-Path $root 'qa/src/load-readiness-operator-preview.html') -Raw
foreach ($requiredPhrase in @(
  'HQ API load-test script',
  'Request-web load-test script',
  'Repeatable readiness-report generation',
  'Pilot-show go/no-go checklist',
  'Pre-show checklist',
  'Post-show checklist',
  'Known-limitations document',
  'Operator quick-start guide',
  'No real load testing',
  'No API calls',
  'No request-web traffic',
  'No readiness report file generation',
  'No server probing',
  'No router changes',
  'No database reads or writes',
  'No network request',
  'No filesystem writes beyond fixtures and docs'
)) {
  if ($html -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Load readiness operator preview shell is missing Wave 14A phrase: $requiredPhrase"
  }
}

$hqScript = Get-Content -LiteralPath (Join-Path $root 'scripts/hq-api-load-test-preview.ps1') -Raw
$requestScript = Get-Content -LiteralPath (Join-Path $root 'scripts/request-web-load-test-preview.ps1') -Raw
foreach ($scriptContent in @($hqScript, $requestScript)) {
  foreach ($forbidden in @('Invoke-WebRequest', 'Invoke-RestMethod', 'Start-Job', 'Start-Sleep', 'New-Item', 'Set-Content')) {
    if ($scriptContent -match [regex]::Escape($forbidden)) {
      throw "Preview load-test scripts must not contain active command: $forbidden"
    }
  }
}

Write-Host 'Load readiness operator smoke test passed: load-test previews, readiness preview, pilot checklist, show checklists, known limitations, operator quick-start, and safety markers are present.'
