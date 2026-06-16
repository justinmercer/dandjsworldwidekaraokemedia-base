$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'scripts/generate-replay-media-intake.ps1',
  'packages/contracts/schemas/replay-media-intake.v1.schema.json',
  'docs/development/replay-media-intake-v1.md'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing replay media intake file: $path"
  }
}

$scriptContent = Get-Content -LiteralPath (Join-Path $root 'scripts/generate-replay-media-intake.ps1') -Raw
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
  'Remove-Item',
  'Get-Item',
  'Test-Path'
)) {
  if ($scriptContent -match [regex]::Escape($forbidden)) {
    throw "Replay media intake generator must not contain forbidden active integration/media command: $forbidden"
  }
}

$tempIntake = Join-Path $env:TEMP ("dandj-replay-media-intake-" + [guid]::NewGuid().ToString() + ".json")

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts/generate-replay-media-intake.ps1') `
  -EventDate '2026-06-15' `
  -VenueName 'Smoke Test Venue' `
  -HostName 'Smoke Test Host' `
  -ShowSessionId 'smoke-test-show-session' `
  -MainRecordingPath 'D:\Karaoke\SmokeTest\main-recording.mp4' `
  -BackupRecordingPath 'D:\Karaoke\SmokeTest\backup-recording.mp4' `
  -OutputPath $tempIntake

if ($LASTEXITCODE -ne 0) {
  throw 'Replay media intake generator exited with a non-zero code.'
}

if (-not (Test-Path -LiteralPath $tempIntake -PathType Leaf)) {
  throw 'Replay media intake was not generated.'
}

$intake = Get-Content -LiteralPath $tempIntake -Raw | ConvertFrom-Json

if ($intake.contractVersion -ne 'v1') { throw 'Unexpected replay media intake contractVersion.' }
if ($intake.kind -ne 'replay-media-intake') { throw 'Unexpected replay media intake kind.' }
if (-not $intake.intakeId.StartsWith('replay-intake-')) { throw 'Replay media intake id was not generated.' }
if ($intake.show.eventDate -ne '2026-06-15') { throw 'Replay media intake event date mismatch.' }
if ($intake.show.venueName -ne 'Smoke Test Venue') { throw 'Replay media intake venue mismatch.' }
if ($intake.show.hostName -ne 'Smoke Test Host') { throw 'Replay media intake host mismatch.' }
if ($intake.show.showSessionId -ne 'smoke-test-show-session') { throw 'Replay media intake show session mismatch.' }
if ($intake.recordings.main.operatorEnteredPath -ne 'D:\Karaoke\SmokeTest\main-recording.mp4') { throw 'Main recording path was not recorded as text.' }
if ($intake.recordings.backup.operatorEnteredPath -ne 'D:\Karaoke\SmokeTest\backup-recording.mp4') { throw 'Backup recording path was not recorded as text.' }
if ($intake.recordings.main.operatorProvided -ne $true) { throw 'Main recording operatorProvided flag mismatch.' }
if ($intake.recordings.backup.operatorProvided -ne $true) { throw 'Backup recording operatorProvided flag mismatch.' }
if ($intake.review.clipPlanningStatus -ne 'not-started') { throw 'Clip planning status mismatch.' }
if ($intake.review.publishApprovalStatus -ne 'not-approved') { throw 'Publish approval status mismatch.' }
if ($intake.processingBoundary.pathsRecordedAsTextOnly -ne $true) { throw 'pathsRecordedAsTextOnly boundary mismatch.' }

foreach ($falseBoundary in @(
  'mediaExistenceChecked',
  'mediaOpened',
  'metadataRead',
  'mediaMovedCopiedRenamedOrDeleted',
  'mediaSplitOrTranscoded',
  'uploadedOrPublished',
  'songRecognitionPerformed',
  'faceRecognitionOrBiometricProcessingPerformed',
  'singerProfilesReadOrWritten'
)) {
  if ($intake.processingBoundary.$falseBoundary -ne $false) {
    throw "Replay media intake boundary should be false: $falseBoundary"
  }
}

$schema = Get-Content -LiteralPath (Join-Path $root 'packages/contracts/schemas/replay-media-intake.v1.schema.json') -Raw | ConvertFrom-Json
if ($schema.title -ne 'Replay Media Intake') { throw 'Replay media intake schema title mismatch.' }
if ($schema.properties.processingBoundary.properties.mediaSplitOrTranscoded.const -ne $false) { throw 'Schema must keep mediaSplitOrTranscoded false.' }
if ($schema.properties.processingBoundary.properties.faceRecognitionOrBiometricProcessingPerformed.const -ne $false) { throw 'Schema must keep face recognition boundary false.' }

Remove-Item -LiteralPath $tempIntake -Force -ErrorAction SilentlyContinue

Write-Host 'Replay media intake smoke test passed: intake generated, recording paths stored as text only, review states initialized, and safety boundaries are false.'
