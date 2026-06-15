$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'scripts/generate-pilot-packet.ps1',
  'docs/development/runtime-pilot-packet-generator.md'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing pilot packet generator file: $path"
  }
}

$scriptContent = Get-Content -LiteralPath (Join-Path $root 'scripts/generate-pilot-packet.ps1') -Raw
foreach ($forbidden in @(
  'Invoke-WebRequest',
  'Invoke-RestMethod',
  'Start-BitsTransfer',
  'curl ',
  'wget ',
  'psql',
  'sqlite3',
  'sqlcmd',
  'Copy-Item',
  'Move-Item',
  'Rename-Item'
)) {
  if ($scriptContent -match [regex]::Escape($forbidden)) {
    throw "Pilot packet generator must not contain forbidden active integration/media command: $forbidden"
  }
}

$tempPacket = Join-Path $env:TEMP ("dandj-pilot-packet-" + [guid]::NewGuid().ToString() + ".md")

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts/generate-pilot-packet.ps1') -OutputPath $tempPacket

if ($LASTEXITCODE -ne 0) {
  throw 'Pilot packet generator exited with a non-zero code.'
}

if (-not (Test-Path -LiteralPath $tempPacket -PathType Leaf)) {
  throw 'Pilot packet was not generated.'
}

$packet = Get-Content -LiteralPath $tempPacket -Raw

foreach ($requiredPhrase in @(
  "D & J's Karaoke Pilot Packet",
  'Current repo readiness',
  'Backlog checked tasks: 577',
  'Backlog unchecked tasks: 0',
  'Operator documents',
  'Suggested pilot flow',
  'Optional local report commands',
  'Safety summary',
  'No media playback is started.',
  'No API request is made.',
  'No network request is made.',
  'No database is read or written.',
  'No singer profile is read or written.',
  'No media file is read, moved, copied, renamed, or deleted.',
  'No face recognition or biometric processing is performed.'
)) {
  if ($packet -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Generated pilot packet is missing phrase: $requiredPhrase"
  }
}

Remove-Item -LiteralPath $tempPacket -Force -ErrorAction SilentlyContinue

Write-Host 'Pilot packet generator smoke test passed: packet generated, backlog counts correct, operator docs listed, pilot flow included, and safety markers are present.'
