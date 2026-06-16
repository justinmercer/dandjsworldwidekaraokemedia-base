$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

foreach ($path in @(
  'scripts/generate-replay-publish-readiness.ps1',
  'docs/development/replay-publish-readiness-v1.md'
)) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing replay publish readiness file: $path"
  }
}

$scriptContent = Get-Content -LiteralPath (Join-Path $root 'scripts/generate-replay-publish-readiness.ps1') -Raw
foreach ($forbidden in @(
  'Invoke-WebRequest',
  'Invoke-RestMethod',
  'Start-BitsTransfer',
  'Start-Process',
  'curl ',
  'wget ',
  'ffmpeg',
  'ffprobe',
  'python ',
  'node ',
  'psql',
  'sqlite3',
  'sqlcmd',
  'Get-ChildItem',
  'Copy-Item',
  'Move-Item',
  'Rename-Item',
  'Remove-Item'
)) {
  if ($scriptContent -match [regex]::Escape($forbidden)) {
    throw "Replay publish readiness generator contains forbidden command: $forbidden"
  }
}

$tempPlan = Join-Path $env:TEMP ("dandj-replay-publish-plan-" + [guid]::NewGuid().ToString() + ".json")
$tempChecklist = Join-Path $env:TEMP ("dandj-replay-publish-checklist-" + [guid]::NewGuid().ToString() + ".md")
$tempReadiness = Join-Path $env:TEMP ("dandj-replay-publish-readiness-" + [guid]::NewGuid().ToString() + ".json")

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts/generate-replay-clip-plan.ps1') `
  -EventDate '2026-06-15' `
  -VenueName 'Smoke Test Venue' `
  -HostName 'Smoke Test Host' `
  -ShowSessionId 'smoke-test-show-session' `
  -SourceIntakeId 'smoke-test-intake' `
  -ClipCount 2 `
  -OutputPath $tempPlan

if ($LASTEXITCODE -ne 0) { throw 'Replay clip plan generator failed.' }

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts/generate-replay-checklist.ps1') `
  -ClipPlanPath $tempPlan `
  -OutputPath $tempChecklist

if ($LASTEXITCODE -ne 0) { throw 'Replay checklist generator failed.' }

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts/generate-replay-publish-readiness.ps1') `
  -ClipPlanPath $tempPlan `
  -ChecklistPath $tempChecklist `
  -OperatorName 'Smoke Test Operator' `
  -OutputPath $tempReadiness

if ($LASTEXITCODE -ne 0) { throw 'Replay publish readiness generator failed.' }
if (-not (Test-Path -LiteralPath $tempReadiness -PathType Leaf)) { throw 'Replay publish readiness file was not generated.' }

$readiness = Get-Content -LiteralPath $tempReadiness -Raw | ConvertFrom-Json

if ($readiness.contractVersion -ne 'v1') { throw 'Unexpected contractVersion.' }
if ($readiness.kind -ne 'replay-publish-readiness') { throw 'Unexpected readiness kind.' }
if ($readiness.operatorName -ne 'Smoke Test Operator') { throw 'Operator mismatch.' }
if ($readiness.sourceIntakeId -ne 'smoke-test-intake') { throw 'Source intake mismatch.' }
if ($readiness.show.venueName -ne 'Smoke Test Venue') { throw 'Venue mismatch.' }
if ($readiness.clips.Count -ne 2) { throw 'Clip count mismatch.' }
if ($readiness.readinessStatus.publishingAllowed -ne $false) { throw 'Publishing must remain disabled by default.' }
if ($readiness.readinessStatus.approvedClipCount -ne 0) { throw 'Approved clip count must start at zero.' }
if ($readiness.clips[0].readiness -ne 'not-approved') { throw 'Clip readiness must start not-approved.' }
if ($readiness.publishingBoundary.readinessRecordOnly -ne $true) { throw 'readinessRecordOnly boundary mismatch.' }

foreach ($falseBoundary in @(
  'mediaOpened',
  'metadataRead',
  'mediaSplitOrTranscoded',
  'overlayRendered',
  'uploadedOrPublished',
  'externalApiCalled',
  'songRecognitionPerformed',
  'personRecognitionPerformed',
  'singerProfilesReadOrWritten'
)) {
  if ($readiness.publishingBoundary.$falseBoundary -ne $false) {
    throw "Boundary should be false: $falseBoundary"
  }
}

Remove-Item -LiteralPath $tempPlan -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $tempChecklist -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $tempReadiness -Force -ErrorAction SilentlyContinue

Write-Host 'Replay publish readiness smoke test passed: readiness JSON generated, publishing remains disabled, and media safety boundaries are false.'
