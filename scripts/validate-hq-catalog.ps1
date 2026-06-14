$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$hqRoot = Join-Path (Join-Path $root 'server') 'hq'
$migrationPath = Join-Path $hqRoot 'database/migrations/0001_authorized_catalog.sql'
$controlsMigrationPath = Join-Path $hqRoot 'database/migrations/0002_catalog_controls.sql'
$hostSyncMigrationPath = Join-Path $hqRoot 'database/migrations/0003_host_sync_foundation.sql'
$seedSqlPath = Join-Path $hqRoot 'database/seeds/0001_demo_catalog.sql'
$seedJsonPath = Join-Path $hqRoot 'data/demo-catalog.json'

foreach ($path in @($migrationPath, $controlsMigrationPath, $hostSyncMigrationPath, $seedSqlPath, $seedJsonPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "Missing HQ catalog file: $path"
  }
}

$migration = Get-Content -LiteralPath $migrationPath -Raw
$controlsMigration = Get-Content -LiteralPath $controlsMigrationPath -Raw
$hostSyncMigration = Get-Content -LiteralPath $hostSyncMigrationPath -Raw
$requiredMigrationTokens = @(
  'CREATE SCHEMA IF NOT EXISTS hq_catalog',
  'CREATE TABLE IF NOT EXISTS hq_catalog.schema_migrations',
  'CREATE TABLE IF NOT EXISTS hq_catalog.songs',
  'CREATE TABLE IF NOT EXISTS hq_catalog.authorized_media_files',
  'CREATE TABLE IF NOT EXISTS hq_catalog.alternate_version_relationships',
  'CREATE TABLE IF NOT EXISTS hq_catalog.catalog_providers',
  'idx_songs_normalized_artist_title',
  'idx_authorized_media_files_sha256_checksum',
  'idx_authorized_media_files_sync_manifest',
  'pg_constraint',
  'songs_preferred_authorized_media_id_fk',
  'storage_relative_key !~'
)

foreach ($token in $requiredMigrationTokens) {
  if ($migration -notlike "*$token*") {
    throw "HQ catalog migration is missing required token: $token"
  }
}

$requiredControlsTokens = @(
  'CREATE TABLE IF NOT EXISTS hq_catalog.catalog_change_audit',
  'before_snapshot jsonb',
  'after_snapshot jsonb',
  'idx_catalog_change_audit_entity_created',
  "VALUES ('0002', 'catalog controls and audit history')"
)

foreach ($token in $requiredControlsTokens) {
  if ($controlsMigration -notlike "*$token*") {
    throw "HQ catalog controls migration is missing required token: $token"
  }
}

$requiredHostSyncTokens = @(
  'CREATE TABLE IF NOT EXISTS hq_catalog.host_devices',
  'display_name text NOT NULL',
  'local_free_space_bytes bigint',
  'local_library_root text',
  'sync_state hq_catalog.host_sync_state',
  'interrupted_sync_state jsonb',
  'ADD COLUMN IF NOT EXISTS sync_manifest_priority',
  'ADD COLUMN IF NOT EXISTS always_keep_on_host',
  'ADD COLUMN IF NOT EXISTS server_archive_only',
  'ADD COLUMN IF NOT EXISTS selected_host_device_ids',
  'ADD COLUMN IF NOT EXISTS requested_song_priority_boost',
  'ADD COLUMN IF NOT EXISTS recently_used_priority_boost',
  'idx_authorized_media_files_selected_hosts',
  "VALUES ('0003', 'host registration and sync manifest foundation')"
)

foreach ($token in $requiredHostSyncTokens) {
  if ($hostSyncMigration -notlike "*$token*") {
    throw "HQ host sync migration is missing required token: $token"
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
    if ($null -eq $media.syncManifestPriority -or $media.syncManifestPriority -lt 0) {
      throw "Sync manifest priority is missing or negative for $($media.authorizedMediaId)."
    }
    if ($null -eq $media.alwaysKeepOnHost -or $null -eq $media.serverArchiveOnly) {
      throw "Sync manifest flags are missing for $($media.authorizedMediaId)."
    }
    if ($null -eq $media.requestedSongPriorityBoost -or $media.requestedSongPriorityBoost -lt 0) {
      throw "Requested-song priority boost is missing or negative for $($media.authorizedMediaId)."
    }
    if ($null -eq $media.recentlyUsedPriorityBoost -or $media.recentlyUsedPriorityBoost -lt 0) {
      throw "Recently-used priority boost is missing or negative for $($media.authorizedMediaId)."
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

Write-Host 'HQ catalog validation passed: migrations, seed metadata, public reads, protected controls, audit tests, host registration, and manifest planning are covered.'
