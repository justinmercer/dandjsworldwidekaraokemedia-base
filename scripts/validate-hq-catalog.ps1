$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$hqRoot = Join-Path (Join-Path $root 'server') 'hq'
$migrationPath = Join-Path $hqRoot 'database/migrations/0001_authorized_catalog.sql'
$seedSqlPath = Join-Path $hqRoot 'database/seeds/0001_demo_catalog.sql'
$seedJsonPath = Join-Path $hqRoot 'data/demo-catalog.json'

foreach ($path in @($migrationPath, $seedSqlPath, $seedJsonPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "Missing HQ catalog file: $path"
  }
}

$migration = Get-Content -LiteralPath $migrationPath -Raw
$requiredMigrationTokens = @(
  'CREATE SCHEMA IF NOT EXISTS hq_catalog',
  'CREATE TABLE IF NOT EXISTS hq_catalog.songs',
  'CREATE TABLE IF NOT EXISTS hq_catalog.authorized_media_files',
  'CREATE TABLE IF NOT EXISTS hq_catalog.alternate_version_relationships',
  'CREATE TABLE IF NOT EXISTS hq_catalog.catalog_providers',
  'idx_songs_normalized_artist_title',
  'idx_authorized_media_files_sha256_checksum',
  'idx_authorized_media_files_sync_manifest',
  'storage_relative_key !~'
)

foreach ($token in $requiredMigrationTokens) {
  if ($migration -notlike "*$token*") {
    throw "HQ catalog migration is missing required token: $token"
  }
}

$catalog = Get-Content -LiteralPath $seedJsonPath -Raw | ConvertFrom-Json
if ($catalog.mode -ne 'development-only') {
  throw 'HQ demo catalog must be marked development-only.'
}

if ($catalog.songs.Count -lt 3) {
  throw 'HQ demo catalog should contain at least three synthetic songs.'
}

foreach ($song in $catalog.songs) {
  if ($song.reviewState -ne 'approved') {
    throw "Public demo song $($song.songId) must be approved."
  }

  if (-not $song.normalizedTitle -or -not $song.normalizedArtist) {
    throw "Public demo song $($song.songId) is missing normalized search fields."
  }

  foreach ($media in $song.media) {
    if ($media.storageRelativeKey -match '(^/|^[A-Za-z]:|^\\\\|(^|/)\.\.(/|$))') {
      throw "Storage-relative key is not relative and opaque for $($media.authorizedMediaId)."
    }
    if ($media.sha256Checksum -notmatch '^[0-9a-f]{64}$') {
      throw "SHA-256 checksum is not a lowercase 64-character hex value for $($media.authorizedMediaId)."
    }
  }
}

$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
  throw 'Node.js is required to validate the runnable HQ catalog service.'
}

Push-Location $hqRoot
try {
  npm test --if-present
  if ($LASTEXITCODE -ne 0) {
    throw 'HQ catalog Node tests failed.'
  }
} finally {
  Pop-Location
}

Write-Host 'HQ catalog validation passed: migration, seed metadata, and read-only endpoints are covered.'
