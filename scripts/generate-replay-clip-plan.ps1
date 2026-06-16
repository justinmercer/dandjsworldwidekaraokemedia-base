param(
  [string]$EventDate = (Get-Date -Format 'yyyy-MM-dd'),
  [string]$VenueName = 'Unspecified venue',
  [string]$HostName = 'Unspecified host',
  [string]$ShowSessionId = ('manual-' + (Get-Date -Format 'yyyyMMdd-HHmmss')),
  [string]$SourceIntakeId = 'operator-to-fill-source-intake-id',
  [int]$ClipCount = 3,
  [string]$OutputPath = 'reports/replay-clip-plan/latest-replay-clip-plan.json'
)

$ErrorActionPreference = 'Stop'

if ($ClipCount -lt 1) {
  throw 'ClipCount must be at least 1.'
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $repoRoot

try {
  $outputFullPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath
  } else {
    Join-Path $repoRoot $OutputPath
  }

  $outputDirectory = Split-Path -Parent $outputFullPath
  if ($outputDirectory) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
  }

  $clips = @()
  foreach ($clipNumber in 1..$ClipCount) {
    $clips += [ordered]@{
      clipNumber = $clipNumber
      clipId = 'manual-clip-' + ('{0:D3}' -f $clipNumber)
      approxStart = 'operator-to-fill-start'
      approxEnd = 'operator-to-fill-end'
      singerDisplayName = 'operator-to-confirm-singer'
      songTitle = 'operator-to-confirm-song'
      artistName = 'operator-to-confirm-artist'
      overlayTitle = 'operator-to-confirm-overlay-title'
      privacyStatus = 'not-reviewed'
      publishDecision = 'not-approved'
      operatorNotes = 'Operator to fill in manually after reviewing the recording.'
    }
  }

  $plan = [ordered]@{
    contractVersion = 'v1'
    kind = 'replay-clip-plan'
    clipPlanId = 'replay-clip-plan-' + [guid]::NewGuid().ToString()
    createdAt = (Get-Date).ToUniversalTime().ToString('o')
    sourceIntakeId = $SourceIntakeId
    show = [ordered]@{
      eventDate = $EventDate
      venueName = $VenueName
      hostName = $HostName
      showSessionId = $ShowSessionId
    }
    clips = $clips
    planStatus = [ordered]@{
      clipRangesReviewed = 'not-reviewed'
      singerNamesReviewed = 'not-reviewed'
      songTitlesReviewed = 'not-reviewed'
      overlayTitlesReviewed = 'not-reviewed'
      privacyReviewed = 'not-reviewed'
      publishApproval = 'not-approved'
    }
    processingBoundary = [ordered]@{
      manualPlanOnly = $true
      mediaOpened = $false
      metadataRead = $false
      mediaSplitOrTranscoded = $false
      overlayRendered = $false
      uploadedOrPublished = $false
      songRecognitionPerformed = $false
      personRecognitionPerformed = $false
      singerProfilesReadOrWritten = $false
    }
  }

  $json = $plan | ConvertTo-Json -Depth 10
  Set-Content -LiteralPath $outputFullPath -Value $json -Encoding UTF8
  Write-Host "Replay clip plan generated: $outputFullPath"
} finally {
  Pop-Location
}
