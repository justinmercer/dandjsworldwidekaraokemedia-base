
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'scripts/generate-pilot-feedback-summary.ps1',
  'docs/development/runtime-pilot-feedback-summary-generator.md'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing pilot feedback summary generator file: $path"
  }
}

$scriptContent = Get-Content -LiteralPath (Join-Path $root 'scripts/generate-pilot-feedback-summary.ps1') -Raw
foreach ($forbidden in @(
  'Invoke-WebRequest',
  'Invoke-RestMethod',
  'Start-BitsTransfer',
  'curl ',
  'wget ',
  'psql',
  'sqlite3',
  'sqlcmd',
  'Remove-Item',
  'Copy-Item',
  'Move-Item',
  'Rename-Item'
)) {
  if ($scriptContent -match [regex]::Escape($forbidden)) {
    throw "Pilot feedback summary generator must not contain forbidden active integration/media command: $forbidden"
  }
}

$tempInput = Join-Path $env:TEMP ("dandj-pilot-feedback-input-" + [guid]::NewGuid().ToString() + ".md")
$tempReport = Join-Path $env:TEMP ("dandj-pilot-feedback-summary-" + [guid]::NewGuid().ToString() + ".md")

$feedback = @(
  '# First-Pilot Feedback Form',
  '',
  '## Show details',
  '',
  '- Venue: Demo Venue',
  '- Date: 2026-06-15',
  '- Operator: Justin',
  '- Approximate singer count: 18',
  '- Approximate request count: 42',
  '',
  '## Feedback',
  '',
  '- What worked well? Singers understood the request screen.',
  '- What confused the operator? The router route was unclear.',
  '- What blocked the show? No blocker found.',
  '- What should be improved before the next pilot? Better pre-show checklist wording.'
)

Set-Content -LiteralPath $tempInput -Value $feedback -Encoding UTF8

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts/generate-pilot-feedback-summary.ps1') -InputPath $tempInput -OutputPath $tempReport

if ($LASTEXITCODE -ne 0) {
  throw 'Pilot feedback summary generator exited with a non-zero code.'
}

if (-not (Test-Path -LiteralPath $tempReport -PathType Leaf)) {
  throw 'Pilot feedback summary report was not generated.'
}

$report = Get-Content -LiteralPath $tempReport -Raw

foreach ($requiredPhrase in @(
  "D & J's Karaoke Pilot Feedback Summary",
  'Source:',
  'Branch:',
  'Commit:',
  'Working tree:',
  'Input lines:',
  'Filled content lines:',
  'Detected sections:',
  'Blocker keyword scan:',
  'Confusion keyword scan: Review needed',
  'Improvement keyword scan: Review suggested',
  'Show details',
  'Feedback',
  'Safety summary',
  'No feedback is submitted anywhere.',
  'No API request is made.',
  'No database is read or written.',
  'No singer profile is read or written.',
  'No media file is read, moved, copied, renamed, or deleted.'
)) {
  if ($report -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Generated pilot feedback summary is missing phrase: $requiredPhrase"
  }
}

Remove-Item -LiteralPath $tempInput -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $tempReport -Force -ErrorAction SilentlyContinue

Write-Host 'Pilot feedback summary generator smoke test passed: report generated, sections found, keyword review flags present, and safety markers are present.'
