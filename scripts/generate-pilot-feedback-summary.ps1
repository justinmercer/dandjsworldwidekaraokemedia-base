
param(
  [string]$InputPath = 'docs/operations/first-pilot-feedback-form.md',
  [string]$OutputPath = 'reports/pilot-feedback/latest-pilot-feedback-summary.md'
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $repoRoot

try {
  $inputFullPath = if ([System.IO.Path]::IsPathRooted($InputPath)) {
    $InputPath
  } else {
    Join-Path $repoRoot $InputPath
  }

  if (-not (Test-Path -LiteralPath $inputFullPath -PathType Leaf)) {
    throw "Pilot feedback input file not found: $inputFullPath"
  }

  $feedback = Get-Content -LiteralPath $inputFullPath -Raw

  $branch = (& git branch --show-current 2>$null)
  if (-not $branch) { $branch = 'unknown' }

  $commit = (& git rev-parse --short HEAD 2>$null)
  if (-not $commit) { $commit = 'unknown' }

  $statusShort = (& git status --short 2>$null)
  $workingTreeState = if ($statusShort) { 'dirty' } else { 'clean' }

  $lineCount = ($feedback -split "\r?\n").Count
  $filledLineCount = (($feedback -split "\r?\n") | Where-Object {
    $line = $_.Trim()
    $line -and
    $line -notmatch '^#' -and
    $line -notmatch '^-$' -and
    $line -notmatch '^##' -and
    $line -notmatch ':\s*$'
  }).Count

  $sections = [regex]::Matches($feedback, '^##\s+(.+)$', [System.Text.RegularExpressions.RegexOptions]::Multiline) |
    ForEach-Object { $_.Groups[1].Value.Trim() }

  $blockedShow = if ($feedback -match '(?i)blocked|blocker|no-go|critical|failed') { 'Review needed' } else { 'No blocker keywords found' }
  $confusionFound = if ($feedback -match '(?i)confus|unclear|hard to|did not understand') { 'Review needed' } else { 'No confusion keywords found' }
  $improvementFound = if ($feedback -match '(?i)improve|better|next pilot|next show|should') { 'Review suggested' } else { 'No improvement keywords found' }

  $outputFullPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath
  } else {
    Join-Path $repoRoot $OutputPath
  }

  $outputDirectory = Split-Path -Parent $outputFullPath
  if ($outputDirectory) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
  }

  $report = @(
    '# D & J''s Karaoke Pilot Feedback Summary',
    '',
    "Generated: $((Get-Date).ToString('s'))",
    "Source: $inputFullPath",
    "Branch: $branch",
    "Commit: $commit",
    "Working tree: $workingTreeState",
    '',
    '## Summary',
    '',
    "Input lines: $lineCount",
    "Filled content lines: $filledLineCount",
    "Detected sections: $($sections.Count)",
    "Blocker keyword scan: $blockedShow",
    "Confusion keyword scan: $confusionFound",
    "Improvement keyword scan: $improvementFound",
    '',
    '## Sections found',
    ''
  )

  if ($sections.Count -gt 0) {
    foreach ($section in $sections) {
      $report += "- $section"
    }
  } else {
    $report += '- No second-level sections found.'
  }

  $report += @(
    '',
    '## Safety summary',
    '',
    '- No feedback is submitted anywhere.',
    '- No API request is made.',
    '- No network request is made.',
    '- No database is read or written.',
    '- No singer profile is read or written.',
    '- No media file is read, moved, copied, renamed, or deleted.',
    '- No cloud service is used.',
    '',
    '## Operator note',
    '',
    'Use this summary as a local review aid after a pilot show. Review the source feedback before making product decisions.'
  )

  Set-Content -LiteralPath $outputFullPath -Value $report -Encoding UTF8
  Write-Host "Pilot feedback summary generated: $outputFullPath"
} finally {
  Pop-Location
}
