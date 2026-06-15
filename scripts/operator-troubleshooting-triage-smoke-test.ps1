
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'docs/development/operator-troubleshooting-triage-shell.md',
  'docs/operations/host-troubleshooting-guide.md',
  'docs/operations/venue-router-troubleshooting-guide.md',
  'docs/operations/obs-companion-troubleshooting-guide.md',
  'docs/operations/recovery-drill-guide.md',
  'docs/operations/first-pilot-feedback-form.md',
  'docs/operations/bug-triage-workflow.md',
  'docs/operations/release-blocker-criteria.md',
  'qa/demo-data/operator-troubleshooting-triage-fixtures.json',
  'qa/src/operator-troubleshooting-triage-preview.html'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing operator troubleshooting triage shell file: $path"
  }
}

$fixtures = Get-Content -LiteralPath (Join-Path $root 'qa/demo-data/operator-troubleshooting-triage-fixtures.json') -Raw | ConvertFrom-Json
foreach ($guard in @(
  'runsTroubleshootingCommands',
  'changesRouter',
  'connectsToObs',
  'connectsToReplay',
  'performsRecoveryAction',
  'submitsFeedback',
  'callsBugTrackerApi',
  'automatesReleaseGate',
  'makesNetworkRequests',
  'readsDatabase',
  'writesDatabase',
  'writesRuntimeFiles'
)) {
  if ($fixtures.$guard -ne $false) {
    throw "Operator troubleshooting triage guard must remain false: $guard"
  }
}

$html = Get-Content -LiteralPath (Join-Path $root 'qa/src/operator-troubleshooting-triage-preview.html') -Raw
foreach ($requiredPhrase in @(
  'Host troubleshooting guide',
  'Venue-router troubleshooting guide',
  'OBS companion troubleshooting guide',
  'Recovery drill guide',
  'First-pilot feedback form',
  'Bug-triage workflow',
  'Release-blocker criteria',
  'No real troubleshooting commands',
  'No router changes',
  'No OBS connection',
  'No Replay connection',
  'No recovery action',
  'No feedback submission',
  'No bug tracker API call',
  'No release gating automation',
  'No network request',
  'No database reads or writes',
  'No filesystem writes beyond fixtures and docs'
)) {
  if ($html -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Operator troubleshooting triage preview shell is missing Wave 14B phrase: $requiredPhrase"
  }
}

$doc = Get-Content -LiteralPath (Join-Path $root 'docs/development/operator-troubleshooting-triage-shell.md') -Raw
foreach ($requiredPhrase in @(
  'Wave 14B adds',
  'host troubleshooting guide',
  'venue-router troubleshooting guide',
  'OBS companion troubleshooting guide',
  'recovery drill guide',
  'first-pilot feedback form',
  'bug-triage workflow',
  'release-blocker criteria'
)) {
  if ($doc -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Operator troubleshooting triage doc is missing Wave 14B phrase: $requiredPhrase"
  }
}

Write-Host 'Operator troubleshooting triage smoke test passed: host, venue-router, OBS companion, recovery drill, feedback form, bug triage, release-blocker criteria, and safety markers are present.'
