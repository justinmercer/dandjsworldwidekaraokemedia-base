param(
  [string]$EventDate = (Get-Date -Format 'yyyy-MM-dd'),
  [string]$VenueName = 'Unspecified venue',
  [string]$HostName = 'Unspecified host',
  [string]$ShowSessionId = ('manual-' + (Get-Date -Format 'yyyyMMdd-HHmmss')),
  [string]$MainRecordingPath = 'operator-to-fill-main-recording-path',
  [string]$BackupRecordingPath = 'operator-to-fill-backup-recording-path',
  [string]$OutputPath = 'reports/replay-media-intake/latest-replay-media-intake.json'
)

$ErrorActionPreference = 'Stop'

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

  $createdAt = (Get-Date).ToUniversalTime().ToString('o')
  $intakeId = 'replay-intake-' + [guid]::NewGuid().ToString()

  $intake = [ordered]@{
    contractVersion = 'v1'
    kind = 'replay-media-intake'
    intakeId = $intakeId
    createdAt = $createdAt
    show = [ordered]@{
      eventDate = $EventDate
      venueName = $VenueName
      hostName = $HostName
      showSessionId = $ShowSessionId
    }
    recordings = [ordered]@{
      main = [ordered]@{
        label = 'main full-show recording'
        operatorEnteredPath = $MainRecordingPath
        operatorProvided = ($MainRecordingPath -ne 'operator-to-fill-main-recording-path')
        existenceChecked = $false
        mediaOpened = $false
        metadataRead = $false
      }
      backup = [ordered]@{
        label = 'backup full-show recording'
        operatorEnteredPath = $BackupRecordingPath
        operatorProvided = ($BackupRecordingPath -ne 'operator-to-fill-backup-recording-path')
        existenceChecked = $false
        mediaOpened = $false
        metadataRead = $false
      }
    }
    review = [ordered]@{
      archiveManifestStatus = 'not-reviewed'
      clipPlanningStatus = 'not-started'
      singerSongReviewStatus = 'not-started'
      overlayTitleReviewStatus = 'not-started'
      privacyReviewStatus = 'not-reviewed'
      publishApprovalStatus = 'not-approved'
    }
    operatorNotes = @(
      'Operator should confirm the full-show recording and backup recording manually before any replay processing.',
      'Recording paths are stored as text only. This generator does not validate, open, scan, or process media files.'
    )
    processingBoundary = [ordered]@{
      pathsRecordedAsTextOnly = $true
      mediaExistenceChecked = $false
      mediaOpened = $false
      metadataRead = $false
      mediaMovedCopiedRenamedOrDeleted = $false
      mediaSplitOrTranscoded = $false
      uploadedOrPublished = $false
      songRecognitionPerformed = $false
      faceRecognitionOrBiometricProcessingPerformed = $false
      singerProfilesReadOrWritten = $false
    }
  }

  $json = $intake | ConvertTo-Json -Depth 10
  Set-Content -LiteralPath $outputFullPath -Value $json -Encoding UTF8
  Write-Host "Replay media intake generated: $outputFullPath"
} finally {
  Pop-Location
}
