
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$requiredFiles = @(
  'host/local-persistence/README.md',
  'host/local-persistence/migrations/0001_local_host_schema.sql',
  'docs/development/host-local-persistence.md'
)

foreach ($path in $requiredFiles) {
  $fullPath = Join-Path $root $path
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Missing host local persistence file: $path"
  }
}

$sql = Get-Content -LiteralPath (Join-Path $root 'host/local-persistence/migrations/0001_local_host_schema.sql') -Raw

foreach ($requiredPhrase in @(
  'CREATE TABLE IF NOT EXISTS local_schema_migrations',
  'CREATE TABLE IF NOT EXISTS local_song_cache',
  'CREATE TABLE IF NOT EXISTS local_singer_profiles',
  'CREATE TABLE IF NOT EXISTS local_show_sessions',
  'CREATE TABLE IF NOT EXISTS local_song_requests',
  'CREATE TABLE IF NOT EXISTS local_venue_profiles',
  'CREATE TABLE IF NOT EXISTS local_sync_status',
  'INSERT OR IGNORE INTO local_schema_migrations'
)) {
  if ($sql -notmatch [regex]::Escape($requiredPhrase)) {
    throw "Local persistence migration is missing required phrase: $requiredPhrase"
  }
}

$forbiddenFiles = Get-ChildItem -LiteralPath (Join-Path $root 'host') -Recurse -File -Force |
  Where-Object { $_.Extension.ToLowerInvariant() -in @('.db', '.sqlite', '.sqlite3') }

if ($forbiddenFiles) {
  throw "Wave 3C must not commit real SQLite database files: $($forbiddenFiles.FullName -join ', ')"
}

Write-Host 'Host local persistence smoke test passed: SQLite schema migration text is present and no database files are committed.'
