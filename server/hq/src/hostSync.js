const { createHash } = require('node:crypto');

const DEFAULT_SYNC_PRIORITY = 100;
const HOST_SYNC_STATES = new Set(['idle', 'interrupted', 'needs_review']);

function toSafeHostDevice(hostDevice) {
  return {
    contractVersion: 'v1',
    hostDeviceId: hostDevice.hostDeviceId,
    displayName: hostDevice.displayName,
    venueLabel: hostDevice.venueLabel || null,
    appVersion: hostDevice.appVersion || null,
    localFreeSpaceBytes: toNullableNumber(hostDevice.localFreeSpaceBytes),
    localLibraryRootReported: Boolean(hostDevice.localLibraryRoot),
    lastSeenAt: hostDevice.lastSeenAt || null,
    isActive: hostDevice.isActive !== false,
    syncState: HOST_SYNC_STATES.has(hostDevice.syncState) ? hostDevice.syncState : 'idle',
    interruptedSyncState: normalizeInterruptedSyncState(hostDevice.interruptedSyncState),
    createdAt: hostDevice.createdAt || null,
    updatedAt: hostDevice.updatedAt || null
  };
}

function createHostSyncManifest({ hostDevice, mediaRecords, generatedAt = new Date().toISOString() }) {
  const safeHostDevice = toSafeHostDevice(hostDevice);
  const entries = mediaRecords
    .filter((record) => shouldIncludeMediaForHost(record, safeHostDevice.hostDeviceId))
    .map(toManifestEntry)
    .sort(compareManifestEntries);
  const manifestVersion = createManifestVersion(entries);

  return {
    contractVersion: 'v1',
    manifestId: `manifest:${safeHostDevice.hostDeviceId}:${manifestVersion.slice(0, 16)}`,
    manifestVersion,
    generatedAt,
    sourceService: 'hq-server',
    targetHostDeviceId: safeHostDevice.hostDeviceId,
    hostDevice: safeHostDevice,
    entries,
    totals: {
      entries: entries.length,
      totalBytes: entries.reduce((total, entry) => total + entry.fileSizeBytes, 0)
    }
  };
}

function diffHostSyncManifest(targetManifest, currentEntries = [], generatedAt = new Date().toISOString()) {
  const targetByKey = new Map(targetManifest.entries.map((entry) => [entry.mediaKey, entry]));
  const currentByKey = new Map(
    currentEntries
      .map(normalizeCurrentManifestEntry)
      .filter((entry) => entry.mediaKey)
      .map((entry) => [entry.mediaKey, entry])
  );

  const additions = [];
  const updates = [];
  const cleanupCandidates = [];

  for (const target of targetManifest.entries) {
    const current = currentByKey.get(target.mediaKey);
    if (!current) {
      additions.push({ action: 'add', entry: target });
      continue;
    }

    if (current.sha256Checksum !== target.sha256Checksum ||
      current.fileSizeBytes !== target.fileSizeBytes ||
      current.versionTimestamp !== target.versionTimestamp) {
      updates.push({
        action: 'update',
        mediaKey: target.mediaKey,
        songId: target.songId,
        authorizedMediaId: target.authorizedMediaId,
        from: {
          sha256Checksum: current.sha256Checksum || null,
          fileSizeBytes: current.fileSizeBytes || null,
          versionTimestamp: current.versionTimestamp || null
        },
        to: target
      });
    }
  }

  for (const current of currentByKey.values()) {
    if (!targetByKey.has(current.mediaKey)) {
      cleanupCandidates.push({
        action: 'review_cleanup_candidate',
        mediaKey: current.mediaKey,
        songId: current.songId || null,
        authorizedMediaId: current.authorizedMediaId || null,
        reviewRequired: true,
        deleteReady: false,
        reason: 'not_in_target_manifest'
      });
    }
  }

  cleanupCandidates.sort((left, right) => left.mediaKey.localeCompare(right.mediaKey));

  return {
    contractVersion: 'v1',
    generatedAt,
    targetManifestId: targetManifest.manifestId,
    targetManifestVersion: targetManifest.manifestVersion,
    targetHostDeviceId: targetManifest.targetHostDeviceId,
    additions,
    updates,
    cleanupCandidates,
    totals: {
      additions: additions.length,
      updates: updates.length,
      cleanupCandidates: cleanupCandidates.length
    }
  };
}

function shouldIncludeMediaForHost(record, hostDeviceId) {
  if (record.serverArchiveOnly) {
    return false;
  }

  const selectedHostDeviceIds = normalizeStringArray(record.selectedHostDeviceIds);
  return selectedHostDeviceIds.length === 0 || selectedHostDeviceIds.includes(hostDeviceId);
}

function toManifestEntry(record) {
  const selectedHostDeviceIds = normalizeStringArray(record.selectedHostDeviceIds);
  const basePriority = toNonNegativeInteger(record.syncManifestPriority, DEFAULT_SYNC_PRIORITY);
  const requestedSongBoost = toNonNegativeInteger(record.requestedSongPriorityBoost, 0);
  const recentlyUsedBoost = toNonNegativeInteger(record.recentlyUsedPriorityBoost, 0);
  const alwaysKeepBoost = record.alwaysKeepOnHost ? 1000 : 0;

  return {
    songId: record.songId,
    authorizedMediaId: record.authorizedMediaId,
    mediaKey: mediaKeyFor(record.authorizedMediaId),
    sha256Checksum: record.sha256Checksum,
    fileSizeBytes: toNonNegativeInteger(record.fileSizeBytes, 0),
    priority: basePriority + requestedSongBoost + recentlyUsedBoost + alwaysKeepBoost,
    versionTimestamp: latestTimestamp(record.mediaUpdatedAt, record.songUpdatedAt),
    songUpdatedAt: record.songUpdatedAt || null,
    mediaUpdatedAt: record.mediaUpdatedAt || null,
    flags: {
      alwaysKeepOnHost: Boolean(record.alwaysKeepOnHost),
      serverArchiveOnly: false,
      selectedHostSync: selectedHostDeviceIds.length > 0
    },
    priorityInputs: {
      basePriority,
      requestedSongBoost,
      recentlyUsedBoost
    }
  };
}

function normalizeCurrentManifestEntry(entry) {
  if (!entry || typeof entry !== 'object') {
    return {};
  }

  const authorizedMediaId = toOptionalString(entry.authorizedMediaId);
  return {
    songId: toOptionalString(entry.songId),
    authorizedMediaId,
    mediaKey: toOptionalString(entry.mediaKey) || (authorizedMediaId ? mediaKeyFor(authorizedMediaId) : null),
    sha256Checksum: toOptionalString(entry.sha256Checksum),
    fileSizeBytes: toNullableNumber(entry.fileSizeBytes),
    versionTimestamp: toOptionalString(entry.versionTimestamp)
  };
}

function normalizeInterruptedSyncState(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    return null;
  }

  return {
    syncId: toOptionalString(value.syncId),
    reason: toOptionalString(value.reason),
    lastMediaKey: toOptionalString(value.lastMediaKey),
    interruptedAt: toOptionalString(value.interruptedAt)
  };
}

function mediaKeyFor(authorizedMediaId) {
  return `authorized-media:${authorizedMediaId}`;
}

function compareManifestEntries(left, right) {
  if (left.priority !== right.priority) {
    return right.priority - left.priority;
  }

  const songCompare = left.songId.localeCompare(right.songId);
  if (songCompare !== 0) {
    return songCompare;
  }

  return left.mediaKey.localeCompare(right.mediaKey);
}

function createManifestVersion(entries) {
  const stableEntries = entries.map((entry) => ({
    mediaKey: entry.mediaKey,
    sha256Checksum: entry.sha256Checksum,
    fileSizeBytes: entry.fileSizeBytes,
    priority: entry.priority,
    versionTimestamp: entry.versionTimestamp
  }));

  return createHash('sha256').update(JSON.stringify(stableEntries)).digest('hex');
}

function latestTimestamp(left, right) {
  const candidates = [left, right].filter(Boolean).sort();
  return candidates[candidates.length - 1] || null;
}

function toOptionalString(value) {
  if (value === undefined || value === null) {
    return null;
  }

  const text = String(value).trim();
  return text || null;
}

function normalizeStringArray(value) {
  if (!Array.isArray(value)) {
    return [];
  }

  return value.map(toOptionalString).filter(Boolean).sort();
}

function toNonNegativeInteger(value, fallback) {
  const number = Number(value);
  return Number.isInteger(number) && number >= 0 ? number : fallback;
}

function toNullableNumber(value) {
  if (value === undefined || value === null || value === '') {
    return null;
  }

  const number = Number(value);
  return Number.isFinite(number) ? number : null;
}

module.exports = {
  HOST_SYNC_STATES,
  createHostSyncManifest,
  diffHostSyncManifest,
  normalizeInterruptedSyncState,
  toSafeHostDevice
};
