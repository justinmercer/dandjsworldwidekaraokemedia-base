const assert = require('node:assert/strict');
const test = require('node:test');
const { CatalogRepository } = require('../src/catalogRepository');
const { loadDemoCatalog, normalizeArtistName, normalizeCatalogText } = require('../src/catalogData');

test('normalizes searchable artist and title text deterministically', () => {
  assert.equal(normalizeCatalogText(' The DEMO-Artist! '), 'the demo artist');
  assert.equal(normalizeCatalogText('Cafe DUET feat. Guest'), 'cafe duet guest');
  assert.equal(normalizeArtistName('The D.J. Demo & Sample Performer'), 'dj demo sample performer');
  assert.equal(normalizeArtistName('Demo Artist and Guest'), 'demo artist guest');
});

test('search returns approved catalog songs with pagination metadata', () => {
  const repository = new CatalogRepository(loadDemoCatalog());
  const result = repository.searchSongs({ query: 'demo', page: 1, pageSize: 1 });

  assert.equal(result.page, 1);
  assert.equal(result.pageSize, 1);
  assert.equal(result.total, 3);
  assert.equal(result.hasNextPage, true);
  assert.equal(result.items.length, 1);
  assert.equal(result.items[0].reviewState, 'approved');
});

test('exact match uses normalized artist and title fields', () => {
  const repository = new CatalogRepository(loadDemoCatalog());
  const match = repository.findExactMatch('demo artist', 'demo opening song');

  assert.equal(match.songId, 'song_demo_opening');
});

test('song details do not expose storage keys or checksums through public output', () => {
  const repository = new CatalogRepository(loadDemoCatalog());
  const detail = repository.getSongDetail('song_demo_opening');
  const serialized = JSON.stringify(detail);

  assert.equal(detail.mediaVersions.length, 2);
  assert.equal(serialized.includes('storageRelativeKey'), false);
  assert.equal(serialized.includes('sha256Checksum'), false);
  assert.equal(serialized.includes('demo-catalog'), false);
});

test('alternate-version listing returns public safe alternate songs', () => {
  const repository = new CatalogRepository(loadDemoCatalog());
  const result = repository.listAlternateVersions('song_demo_opening');

  assert.equal(result.total, 1);
  assert.equal(result.items[0].relationshipId, 'alternate_demo_opening_duet');
  assert.equal(result.items[0].alternateSong.songId, 'song_demo_duet');
  assert.equal(JSON.stringify(result).includes('notes'), false);
});

test('catalog writes produce protected audit history records', () => {
  const repository = new CatalogRepository(loadDemoCatalog());
  const song = repository.createSong({
    songId: 'song_demo_admin_created',
    title: 'Cafe Demo & Guest',
    artistName: 'The D.J. Demo feat. Guest',
    language: 'en',
    reviewState: 'pending_review',
    authorizationNotes: 'Synthetic admin-created metadata only.'
  }, {
    actorLabel: 'test-admin',
    changeReason: 'node test'
  });

  assert.equal(song.normalizedTitle, 'cafe demo guest');
  assert.equal(song.normalizedArtist, 'dj demo guest');

  const updated = repository.updateSong(song.songId, { title: 'Cafe Demo Final' }, { actorLabel: 'test-admin' });
  assert.equal(updated.normalizedTitle, 'cafe demo final');

  const reviewed = repository.setReviewState(song.songId, 'approved', { actorLabel: 'test-admin' });
  assert.equal(reviewed.reviewState, 'approved');

  const noted = repository.updateSourceNotes(song.songId, 'Synthetic note update.', { actorLabel: 'test-admin' });
  assert.equal(noted.authorizationNotes, 'Synthetic note update.');

  const retired = repository.retireSong(song.songId, 'Synthetic retirement.', { actorLabel: 'test-admin' });
  assert.equal(retired.reviewState, 'retired');
  assert.equal(retired.retirementReason, 'Synthetic retirement.');

  const audit = repository.getAuditHistory({ entityType: 'song', entityId: song.songId, pageSize: 10 });
  assert.equal(audit.total, 5);
  assert.equal(audit.items.every((item) => item.actorLabel === 'test-admin'), true);
});

test('host registration heartbeat manifest planning and diffing stay safe', () => {
  const repository = new CatalogRepository(loadDemoCatalog());
  const host = repository.registerHostDevice({
    hostDeviceId: 'host_demo_main',
    displayName: 'Demo Booth Laptop',
    venueLabel: 'Demo Venue',
    appVersion: '0.2.0-demo',
    localFreeSpaceBytes: 123456789,
    localLibraryRoot: 'C:\\Demo\\Karaoke'
  });

  assert.equal(host.hostDeviceId, 'host_demo_main');
  assert.equal(host.localLibraryRootReported, true);
  assert.equal(JSON.stringify(host).includes('C:\\Demo\\Karaoke'), false);

  const heartbeat = repository.updateHostHeartbeat('host_demo_main', {
    appVersion: '0.2.1-demo',
    localFreeSpaceBytes: 123450000,
    isActive: true,
    syncState: 'interrupted',
    interruptedSyncState: {
      syncId: 'sync-demo-001',
      reason: 'Synthetic interrupted sync marker.',
      lastMediaKey: 'authorized-media:media_demo_opening_cdg',
      interruptedAt: '2026-06-14T00:00:00Z'
    }
  });

  assert.equal(heartbeat.syncState, 'interrupted');
  assert.equal(heartbeat.interruptedSyncState.lastMediaKey, 'authorized-media:media_demo_opening_cdg');

  const statuses = repository.listHostStatuses();
  assert.equal(statuses.total, 1);
  assert.equal(statuses.items[0].displayName, 'Demo Booth Laptop');

  const manifest = repository.createHostManifest('host_demo_main');
  const serializedManifest = JSON.stringify(manifest);
  assert.equal(manifest.entries.length, 3);
  assert.equal(manifest.entries[0].authorizedMediaId, 'media_demo_opening_cdg');
  assert.equal(manifest.entries.some((entry) => entry.authorizedMediaId === 'media_demo_opening_guide'), false);
  assert.equal(manifest.entries.some((entry) => entry.authorizedMediaId === 'media_demo_finale_cdg'), true);
  assert.equal(manifest.entries[0].flags.alwaysKeepOnHost, true);
  assert.equal(manifest.entries[0].priorityInputs.requestedSongBoost, 30);
  assert.equal(serializedManifest.includes('storageRelativeKey'), false);
  assert.equal(serializedManifest.includes('demo-catalog'), false);
  assert.match(manifest.manifestVersion, /^[0-9a-f]{64}$/);

  const repeatManifest = repository.createHostManifest('host_demo_main');
  assert.deepEqual(
    repeatManifest.entries.map((entry) => entry.mediaKey),
    manifest.entries.map((entry) => entry.mediaKey)
  );
  assert.equal(repeatManifest.manifestVersion, manifest.manifestVersion);

  const diff = repository.diffHostManifest('host_demo_main', [
    {
      songId: 'song_demo_opening',
      authorizedMediaId: 'media_demo_opening_cdg',
      sha256Checksum: '0000000000000000000000000000000000000000000000000000000000000000',
      fileSizeBytes: 1,
      versionTimestamp: '2026-01-01T00:00:00Z'
    },
    {
      songId: 'song_demo_stale',
      authorizedMediaId: 'media_demo_stale',
      sha256Checksum: '5555555555555555555555555555555555555555555555555555555555555555',
      fileSizeBytes: 10,
      versionTimestamp: '2026-01-01T00:00:00Z'
    }
  ]);

  assert.equal(diff.totals.additions, 2);
  assert.equal(diff.totals.updates, 1);
  assert.equal(diff.totals.cleanupCandidates, 1);
  assert.equal(diff.cleanupCandidates[0].action, 'review_cleanup_candidate');
  assert.equal(diff.cleanupCandidates[0].deleteReady, false);
});


test('sync control repository methods store safe planning metadata without file actions', () => {
  const repository = new CatalogRepository(loadDemoCatalog());
  repository.registerHostDevice({
    hostDeviceId: 'host_sync_controls',
    displayName: 'Sync Control Test Host'
  });

  const operation = repository.createHostSyncOperation('host_sync_controls', {
    operationKind: 'verify_library',
    status: 'syncing',
    progress: { totalEntries: 3, completedEntries: 1, pendingEntries: 2, failedEntries: 0, bytesTotal: 300, bytesCompleted: 100, percentComplete: 33 }
  });
  assert.equal(operation.status, 'syncing');
  assert.equal(operation.progress.totalEntries, 3);

  const verified = repository.updateHostSyncOperation(operation.syncOperationId, {
    status: 'verified',
    verification: { checksumAlgorithm: 'sha256', result: 'passed' }
  });
  assert.equal(verified.status, 'verified');
  assert.equal(verified.verification.result, 'passed');

  const operations = repository.listHostSyncOperations('host_sync_controls');
  assert.equal(operations.total, 1);
  assert.equal(operations.items[0].syncOperationId, operation.syncOperationId);

  const action = repository.queueHostSyncOperatorAction('host_sync_controls', {
    action: 'sync_now',
    requestedBy: 'unit-test-admin',
    reason: 'Synthetic planning-only sync action.',
    payload: { dryRun: true }
  });
  assert.equal(action.status, 'queued');
  assert.equal(action.safetyMode, 'plan_only');
  assert.deepEqual(action.payload, { dryRun: true });

  const actions = repository.listHostSyncOperatorActions('host_sync_controls');
  assert.equal(actions.total, 1);
  assert.equal(actions.items[0].action, 'sync_now');

  const quarantine = repository.recordHostSyncQuarantine('host_sync_controls', {
    syncOperationId: operation.syncOperationId,
    authorizedMediaId: 'media_demo_opening_cdg',
    reason: 'Synthetic checksum mismatch marker.',
    verification: { expected: 'sha256-placeholder', actual: 'sha256-placeholder-other' },
    quarantineKey: 'host-sync-quarantine/media_demo_opening_cdg'
  });
  assert.equal(quarantine.reason, 'Synthetic checksum mismatch marker.');
  assert.equal(quarantine.quarantineKey, 'host-sync-quarantine/media_demo_opening_cdg');

  const quarantined = repository.listHostSyncQuarantine('host_sync_controls');
  assert.equal(quarantined.total, 1);
  assert.equal(JSON.stringify(quarantined).includes('C:\\'), false);
});
