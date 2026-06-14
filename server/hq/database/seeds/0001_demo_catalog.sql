INSERT INTO hq_catalog.catalog_providers (
  provider_id,
  provider_code,
  display_name,
  source_type,
  authorization_notes,
  created_at,
  updated_at
) VALUES
  (
    '00000000-0000-4000-8000-000000000101',
    'operator_demo',
    'Demo Operator Library',
    'operator_authorized',
    'Synthetic provider record for local development only.',
    '2026-06-13T00:00:00Z',
    '2026-06-13T00:00:00Z'
  ),
  (
    '00000000-0000-4000-8000-000000000102',
    'partner_demo',
    'Demo Partner Catalog',
    'licensed_partner',
    'Synthetic partner-style source for metadata tests only.',
    '2026-06-13T00:00:00Z',
    '2026-06-13T00:00:00Z'
  )
ON CONFLICT (provider_id) DO NOTHING;

INSERT INTO hq_catalog.songs (
  song_id,
  title,
  artist_name,
  normalized_title,
  normalized_artist,
  language_code,
  review_state,
  quality_rating,
  authorization_notes,
  last_verified_at,
  created_at,
  updated_at
) VALUES
  (
    '00000000-0000-4000-8000-000000000201',
    'Demo Opening Song',
    'Demo Artist',
    'demo opening song',
    'demo artist',
    'en',
    'approved',
    4,
    'Synthetic authorized catalog song. No real karaoke media is referenced.',
    '2026-06-13T00:00:00Z',
    '2026-06-13T00:00:00Z',
    '2026-06-13T00:00:00Z'
  ),
  (
    '00000000-0000-4000-8000-000000000202',
    'Demo Finale Song',
    'Sample Performer',
    'demo finale song',
    'sample performer',
    'en',
    'approved',
    5,
    'Synthetic authorized catalog song. No real karaoke media is referenced.',
    '2026-06-13T00:00:00Z',
    '2026-06-13T00:00:00Z',
    '2026-06-13T00:00:00Z'
  ),
  (
    '00000000-0000-4000-8000-000000000203',
    'Demo Duet Version',
    'Demo Artist',
    'demo duet version',
    'demo artist',
    'en',
    'approved',
    3,
    'Synthetic authorized alternate-version song for relationship modeling.',
    '2026-06-13T00:00:00Z',
    '2026-06-13T00:00:00Z',
    '2026-06-13T00:00:00Z'
  )
ON CONFLICT (song_id) DO NOTHING;

INSERT INTO hq_catalog.authorized_media_files (
  authorized_media_id,
  song_id,
  provider_id,
  provider_track_id,
  sha256_checksum,
  file_size_bytes,
  duration_seconds,
  file_format,
  vocal_guide_type,
  storage_relative_key,
  is_preferred_version,
  review_state,
  quality_rating,
  authorization_notes,
  last_verified_at,
  created_at,
  updated_at
) VALUES
  (
    '00000000-0000-4000-8000-000000000301',
    '00000000-0000-4000-8000-000000000201',
    '00000000-0000-4000-8000-000000000101',
    'DEMO-OPEN-001',
    '1111111111111111111111111111111111111111111111111111111111111111',
    12582912,
    184,
    'cdg_mp3_bundle',
    'none',
    'demo-catalog/opening/primary',
    true,
    'approved',
    4,
    'Synthetic opaque storage reference only.',
    '2026-06-13T00:00:00Z',
    '2026-06-13T00:00:00Z',
    '2026-06-13T00:00:00Z'
  ),
  (
    '00000000-0000-4000-8000-000000000302',
    '00000000-0000-4000-8000-000000000201',
    '00000000-0000-4000-8000-000000000101',
    'DEMO-OPEN-001-GUIDE',
    '2222222222222222222222222222222222222222222222222222222222222222',
    13631488,
    184,
    'mp4_karaoke',
    'guide_vocal',
    'demo-catalog/opening/guide',
    false,
    'approved',
    3,
    'Synthetic alternate guide-vocal reference only.',
    '2026-06-13T00:00:00Z',
    '2026-06-13T00:00:00Z',
    '2026-06-13T00:00:00Z'
  ),
  (
    '00000000-0000-4000-8000-000000000303',
    '00000000-0000-4000-8000-000000000202',
    '00000000-0000-4000-8000-000000000102',
    'DEMO-FINALE-001',
    '3333333333333333333333333333333333333333333333333333333333333333',
    15728640,
    213,
    'cdg_mp3_bundle',
    'none',
    'demo-catalog/finale/primary',
    true,
    'approved',
    5,
    'Synthetic opaque storage reference only.',
    '2026-06-13T00:00:00Z',
    '2026-06-13T00:00:00Z',
    '2026-06-13T00:00:00Z'
  ),
  (
    '00000000-0000-4000-8000-000000000304',
    '00000000-0000-4000-8000-000000000203',
    '00000000-0000-4000-8000-000000000101',
    'DEMO-DUET-001',
    '4444444444444444444444444444444444444444444444444444444444444444',
    14680064,
    201,
    'cdg_mp3_bundle',
    'duet',
    'demo-catalog/duet/primary',
    true,
    'approved',
    3,
    'Synthetic opaque storage reference only.',
    '2026-06-13T00:00:00Z',
    '2026-06-13T00:00:00Z',
    '2026-06-13T00:00:00Z'
  )
ON CONFLICT (authorized_media_id) DO NOTHING;

UPDATE hq_catalog.authorized_media_files
SET sync_manifest_priority = 120,
    always_keep_on_host = true,
    server_archive_only = false,
    selected_host_device_ids = ARRAY[]::uuid[],
    requested_song_priority_boost = 30,
    recently_used_priority_boost = 10
WHERE authorized_media_id = '00000000-0000-4000-8000-000000000301';

UPDATE hq_catalog.authorized_media_files
SET sync_manifest_priority = 50,
    always_keep_on_host = false,
    server_archive_only = true,
    selected_host_device_ids = ARRAY[]::uuid[],
    requested_song_priority_boost = 0,
    recently_used_priority_boost = 0
WHERE authorized_media_id = '00000000-0000-4000-8000-000000000302';

UPDATE hq_catalog.authorized_media_files
SET sync_manifest_priority = 90,
    always_keep_on_host = false,
    server_archive_only = false,
    selected_host_device_ids = ARRAY['00000000-0000-4000-8000-000000000901']::uuid[],
    requested_song_priority_boost = 0,
    recently_used_priority_boost = 0
WHERE authorized_media_id = '00000000-0000-4000-8000-000000000303';

UPDATE hq_catalog.authorized_media_files
SET sync_manifest_priority = 100,
    always_keep_on_host = false,
    server_archive_only = false,
    selected_host_device_ids = ARRAY[]::uuid[],
    requested_song_priority_boost = 0,
    recently_used_priority_boost = 25
WHERE authorized_media_id = '00000000-0000-4000-8000-000000000304';

UPDATE hq_catalog.songs
SET preferred_authorized_media_id = media.authorized_media_id
FROM hq_catalog.authorized_media_files AS media
WHERE hq_catalog.songs.song_id = media.song_id
  AND media.is_preferred_version
  AND hq_catalog.songs.preferred_authorized_media_id IS NULL;

INSERT INTO hq_catalog.alternate_version_relationships (
  relationship_id,
  song_id,
  alternate_song_id,
  relationship_type,
  notes,
  created_at,
  updated_at
) VALUES (
  '00000000-0000-4000-8000-000000000401',
  '00000000-0000-4000-8000-000000000201',
  '00000000-0000-4000-8000-000000000203',
  'alternate_arrangement',
  'Synthetic relationship record for migration and seed validation only.',
  '2026-06-13T00:00:00Z',
  '2026-06-13T00:00:00Z'
)
ON CONFLICT (relationship_id) DO NOTHING;
