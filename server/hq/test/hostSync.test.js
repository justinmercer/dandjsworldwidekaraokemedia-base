const assert = require('node:assert/strict');
const test = require('node:test');
const { CatalogRepository } = require('../src/catalogRepository');
const { loadDemoCatalog } = require('../src/catalogData');
const { createHostSyncManifest, diffHostSyncManifest, normalizeInterruptedSyncState } = require('../src/hostSync');

const GENERATED_AT = '2026-06-14T00:00:00.000Z';

function hostDevice(overrides = {}) {
  return {
    hostDeviceId: 'host_sync_test',
    displayName: 'Sync Test Host',
    venueLabel: 'Demo Venue',
    appVersion: '0.2.0-test',
    localFreeSpaceBytes: 500000,
    localLibraryRoot: 'C:\\Demo\\Karaoke',
    syncState: 'idle',
    ...overrides
  };
}

function mediaRecord(overrides = {}) {
  const authorizedMediaId = overrides.authorizedMediaId || 'media_default';
  return {
    songId: 'song_default',
    authorizedMediaId,
    sha256Checksum: 'a'.repeat(64),
    fileSizeBytes: 100,
    songUpdatedAt: '2026-06-01T00:00:00.000Z',
    mediaUpdatedAt: '2026-06-02T00:00:00.000Z',
    syncManifestPriority: 100,
    alwaysKeepOnHost: false,
    serverArchiveOnly: false,
    selectedHostDeviceIds: [],
    requestedSongPriorityBoost: 0,
    recentlyUsedPriorityBoost: 0,
    ...overrides
  };
}

test('host sync manifests keep deterministic order independent of input order', () => {
  const unorderedRecords = [
    mediaRecord({ songId: 'song_b', authorizedMediaId: 'media_song_b', sha256Checksum: 'b'.repeat(64), syncManifestPriority: 100 }),
    mediaRecord({ songId: 'song_a', authorizedMediaId: 'media_song_a_b', sha256Checksum: 'c'.repeat(64), syncManifestPriority: 100 }),
    mediaRecord({ songId: 'song_high', authorizedMediaId: 'media_priority_high', sha256Checksum: 'd'.repeat(64), syncManifestPriority: 250 }),
    mediaRecord({ songId: 'song_a', authorizedMediaId: 'media_song_a_a', sha256Checksum: 'e'.repeat(64), syncManifestPriority: 100 })
  ];

  const manifest = createHostSyncManifest({
    hostDevice: hostDevice(),
    mediaRecords: unorderedRecords,
    generatedAt: GENERATED_AT
  });

  assert.deepEqual(manifest.entries.map((entry) => entry.mediaKey), [
    'authorized-media:media_priority_high',
    'authorized-media:media_song_a_a',
    'authorized-media:media_song_a_b',
    'authorized-media:media_song_b'
  ]);

  const repeatManifest = createHostSyncManifest({
    hostDevice: hostDevice(),
    mediaRecords: [...unorderedRecords].reverse(),
    generatedAt: '2026-06-14T01:00:00.000Z'
  });

  assert.deepEqual(
    repeatManifest.entries.map((entry) => entry.mediaKey),
    manifest.entries.map((entry) => entry.mediaKey)
  );
  assert.equal(repeatManifest.manifestVersion, manifest.manifestVersion);
  assert.equal(JSON.stringify(manifest).includes('C:\\Demo\\Karaoke'), false);
});

test('host manifest diffs report additions updates and review-first cleanup candidates', () => {
  const targetManifest = createHostSyncManifest({
    hostDevice: hostDevice(),
    mediaRecords: [
      mediaRecord({ songId: 'song_add_one', authorizedMediaId: 'media_sync_add_1', sha256Checksum: '1'.repeat(64), fileSizeBytes: 111 }),
      mediaRecord({ songId: 'song_add_two', authorizedMediaId: 'media_sync_add_2', sha256Checksum: '2'.repeat(64), fileSizeBytes: 222 })
    ],
    generatedAt: GENERATED_AT
  });

  const emptyDiff = diffHostSyncManifest(targetManifest, [], GENERATED_AT);
  assert.equal(emptyDiff.totals.additions, 2);
  assert.deepEqual(emptyDiff.additions.map((addition) => addition.entry.mediaKey), [
    'authorized-media:media_sync_add_1',
    'authorized-media:media_sync_add_2'
  ]);

  const changedDiff = diffHostSyncManifest(targetManifest, [
    {
      authorizedMediaId: 'media_sync_add_1',
      sha256Checksum: '0'.repeat(64),
      fileSizeBytes: 10,
      versionTimestamp: '2026-01-01T00:00:00.000Z'
    },
    {
      authorizedMediaId: 'media_local_stale',
      songId: 'song_local_stale',
      sha256Checksum: '9'.repeat(64),
      fileSizeBytes: 999,
      versionTimestamp: '2026-01-01T00:00:00.000Z'
    }
  ], GENERATED_AT);

  assert.equal(changedDiff.totals.additions, 1);
  assert.equal(changedDiff.additions[0].entry.mediaKey, 'authorized-media:media_sync_add_2');
  assert.equal(changedDiff.totals.updates, 1);
  assert.equal(changedDiff.updates[0].mediaKey, 'authorized-media:media_sync_add_1');
  assert.equal(changedDiff.updates[0].from.sha256Checksum, '0'.repeat(64));
  assert.equal(changedDiff.updates[0].to.sha256Checksum, '1'.repeat(64));
  assert.equal(changedDiff.totals.cleanupCandidates, 1);
  assert.equal(changedDiff.cleanupCandidates[0].action, 'review_cleanup_candidate');
  assert.equal(changedDiff.cleanupCandidates[0].reviewRequired, true);
  assert.equal(changedDiff.cleanupCandidates[0].deleteReady, false);
});

test('sync control tests cover insufficient disk space interrupted operations retries and checksum quarantine', () => {
  const repository = new CatalogRepository(loadDemoCatalog());
  repository.registerHostDevice({
    hostDeviceId: 'host_sync_failure_tests',
    displayName: 'Failure Planning Host',
    localLibraryRoot: 'C:\\Demo\\Karaoke'
  });

  const operation = repository.createHostSyncOperation('host_sync_failure_tests', {
    operationKind: 'sync',
    status: 'failed',
    progress: {
      totalEntries: 3,
      completedEntries: 1,
      pendingEntries: 1,
      failedEntries: 1,
      bytesTotal: 300,
      bytesCompleted: 100,
      percentComplete: 33
    },
    capacityCheck: {
      localFreeSpaceBytes: 100,
      requiredBytes: 300,
      isSufficient: false
    },
    verification: {
      checksumAlgorithm: 'sha256',
      result: 'failed',
      expectedChecksum: 'a'.repeat(64),
      actualChecksum: 'b'.repeat(64)
    },
    quarantine: {
      required: true,
      quarantineKey: 'host-sync-quarantine/media_demo_opening_cdg'
    },
    retryPolicy: {
      attempt: 2,
      maxAttempts: 3,
      nextRetryAt: '2026-06-14T00:05:00.000Z',
      backoffSeconds: 60
    },
    lastError: {
      code: 'insufficient_disk_space',
      message: 'Synthetic insufficient capacity marker.'
    }
  });

  assert.equal(operation.capacityCheck.isSufficient, false);
  assert.equal(operation.capacityCheck.localFreeSpaceBytes, 100);
  assert.equal(operation.capacityCheck.requiredBytes, 300);
  assert.equal(operation.retryPolicy.attempt, 2);
  assert.equal(operation.retryPolicy.backoffSeconds, 60);
  assert.equal(operation.verification.result, 'failed');
  assert.equal(operation.quarantine.required, true);

  const heartbeat = repository.updateHostHeartbeat('host_sync_failure_tests', {
    syncState: 'interrupted',
    interruptedSyncState: {
      syncId: 'sync-interrupted-001',
      reason: 'Synthetic network drop during planning test.',
      lastMediaKey: 'authorized-media:media_demo_opening_cdg',
      interruptedAt: '2026-06-14T00:03:00.000Z'
    }
  });
  assert.equal(heartbeat.syncState, 'interrupted');
  assert.equal(heartbeat.interruptedSyncState.lastMediaKey, 'authorized-media:media_demo_opening_cdg');

  const normalizedInterrupted = normalizeInterruptedSyncState({
    syncId: ' sync-interrupted-002 ',
    reason: ' Resume test ',
    lastMediaKey: ' authorized-media:media_demo_finale_cdg ',
    interruptedAt: ' 2026-06-14T00:04:00.000Z '
  });
  assert.equal(normalizedInterrupted.syncId, 'sync-interrupted-002');
  assert.equal(normalizedInterrupted.reason, 'Resume test');
  assert.equal(normalizedInterrupted.lastMediaKey, 'authorized-media:media_demo_finale_cdg');

  const quarantine = repository.recordHostSyncQuarantine('host_sync_failure_tests', {
    syncOperationId: operation.syncOperationId,
    authorizedMediaId: 'media_demo_opening_cdg',
    reason: 'checksum_mismatch',
    verification: {
      expectedChecksum: 'a'.repeat(64),
      actualChecksum: 'b'.repeat(64),
      algorithm: 'sha256'
    },
    quarantineKey: 'host-sync-quarantine/media_demo_opening_cdg'
  });

  assert.equal(quarantine.reason, 'checksum_mismatch');
  assert.equal(quarantine.verification.expectedChecksum, 'a'.repeat(64));
  assert.equal(quarantine.verification.actualChecksum, 'b'.repeat(64));
  assert.equal(quarantine.quarantineKey, 'host-sync-quarantine/media_demo_opening_cdg');

  const summary = repository.getHostSyncSummary('host_sync_failure_tests');
  assert.equal(summary.statusCounts.failed, 1);
  assert.equal(summary.lastError.code, 'insufficient_disk_space');
  assert.equal(summary.progress.failedEntries, 1);
  assert.equal(summary.quarantineCount, 1);
  assert.equal(JSON.stringify({ operation, heartbeat, quarantine, summary }).includes('C:\\Demo\\Karaoke'), false);
});
