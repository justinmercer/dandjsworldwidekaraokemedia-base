param(
  [string]$ChecklistPath = 'reports/replay-checklist/latest-replay-checklist.md',
  [string]$ClipPlanPath = 'reports/replay-clip-plan/latest-replay-clip-plan.json',
  [string]$OperatorName = 'Unspecified operator',
  [string]$OutputPath = 'reports/replay-publish-readiness/latest-replay-publish-readiness.json'
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $repoRoot

try {
  $clipPlanFullPath = if ([System.IO.Path]::IsPathRooted($ClipPlanPath)) {
    $ClipPlanPath
  } else {
    Join-Path $repoRoot $ClipPlanPath
  }

  $checklistFullPath = if ([System.IO.Path]::IsPathRooted($ChecklistPath)) {
    $ChecklistPath
  } else {
    Join-Path $repoRoot $ChecklistPath
  }

  if (-not (Test-Path -LiteralPath $clipPlanFullPath -PathType Leaf)) {
    throw "Clip plan file not found: $ClipPlanPath"
  }

  if (-not (Test-Path -LiteralPath $checklistFullPath -PathType Leaf)) {
    throw "Checklist file not found: $ChecklistPath"
  }

  $clipPlan = Get-Content -LiteralPath $clipPlanFullPath -Raw | ConvertFrom-Json
  $checklist = Get-Content -LiteralPath $checklistFullPath -Raw

  if ($clipPlan.kind -ne 'replay-clip-plan') {
    throw 'Input file is not a replay clip plan.'
  }

  if ($checklist -notmatch [regex]::Escape("D & J's Karaoke Replay Checklist")) {
    throw 'Input checklist does not look like a replay checklist.'
  }

  $outputFullPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath
  } else {
    Join-Path $repoRoot $OutputPath
  }

  $outputDirectory = Split-Path -Parent $outputFullPath
  if ($outputDirectory) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
  }

  $clipSummaries = @()
  foreach ($clip in $clipPlan.clips) {
    $clipSummaries += [ordered]@{
      clipNumber = $clip.clipNumber
      clipId = $clip.clipId
      singerDisplayName = $clip.singerDisplayName
      songTitle = $clip.songTitle
      artistName = $clip.artistName
      overlayTitle = $clip.overlayTitle
      privacyStatus = $clip.privacyStatus
      publishDecision = $clip.publishDecision
      readiness = if ($clip.publishDecision -eq 'approved') { 'operator-approved' } else { 'not-approved' }
    }
  }

  $readiness = [ordered]@{
    contractVersion = 'v1'
    kind = 'replay-publish-readiness'
    readinessId = 'replay-publish-readiness-' + [guid]::NewGuid().ToString()
    createdAt = (Get-Date).ToUniversalTime().ToString('o')
    operatorName = $OperatorName
    sourceChecklistPath = $ChecklistPath
    sourceClipPlanPath = $ClipPlanPath
    sourceClipPlanId = $clipPlan.clipPlanId
    sourceIntakeId = $clipPlan.sourceIntakeId
    show = [ordered]@{
      eventDate = $clipPlan.show.eventDate
      venueName = $clipPlan.show.venueName
      hostName = $clipPlan.show.hostName
      showSessionId = $clipPlan.show.showSessionId
    }
    readinessStatus = [ordered]@{
      operatorChecklistReviewed = 'operator-to-confirm'
      clipRangesConfirmed = 'operator-to-confirm'
      singerSongArtistConfirmed = 'operator-to-confirm'
      overlayTitlesConfirmed = 'operator-to-confirm'
      privacyConfirmed = 'operator-to-confirm'
      approvedClipCount = 0
      publishingAllowed = $false
    }
    clips = $clipSummaries
    publishingBoundary = [ordered]@{
      readinessRecordOnly = $true
      mediaOpened = $false
      metadataRead = $false
      mediaSplitOrTranscoded = $false
      overlayRendered = $false
      uploadedOrPublished = $false
      platformCredentialsRead = $false
      externalApiCalled = $false
      songRecognitionPerformed = $false
      personRecognitionPerformed = $false
      singerProfilesReadOrWritten = $false
    }
  }

  $json = $readiness | ConvertTo-Json -Depth 10
  Set-Content -LiteralPath $outputFullPath -Value $json -Encoding UTF8
  Write-Host "Replay publish readiness generated: $outputFullPath"
} finally {
  Pop-Location
}
