const { randomUUID } = require('node:crypto');
const {
  createHostSyncManifest,
  diffHostSyncManifest,
  normalizeInterruptedSyncState,
  toSafeHostDevice
} = require('./hostSync');
const { normalizeArtistName, normalizeCatalogText } = require('./normalization');

const DEFAULT_PAGE_SIZE = 20;
const MAX_PAGE_SIZE = 50;

class CatalogRepository {
  constructor(catalog) {
    this.catalog = catalog;
    this.providersById = new Map((catalog.providers || []).map((provider) => [provider.providerId, provider]));
    this.songsById = new Map((catalog.songs || []).map((song) => [song.songId, song]));
    this.hostDevicesById = new Map((catalog.hostDevices || []).map((hostDevice) => [hostDevice.hostDeviceId, hostDevice]));
    this.hostSyncOperationsById = new Map((catalog.hostSyncOperations || []).map((operation) => [operation.syncOperationId, operation]));
    this.hostSyncOperatorActionsById = new Map((catalog.hostSyncOperatorActions || []).map((action) => [action.syncActionId, action]));
    this.hostSyncQuarantineById = new Map((catalog.hostSyncQuarantine || []).map((quarantine) => [quarantine.syncQuarantineId, quarantine]));
    this.auditRecords = [];
  }

  getHealth() {
    const mediaCount = (this.catalog.songs || []).reduce((count, song) => count + (song.media || []).length, 0);

    return {
      status: 'ok',
      service: 'hq-catalog',
      framework: 'node:http',
      catalogVersion: this.catalog.catalogVersion,
      migrationVersion: '0001_authorized_catalog',
      mode: this.catalog.mode,
      counts: {
        songs: this.catalog.songs.length,
        providers: this.catalog.providers.length,
        authorizedMediaFiles: mediaCount
      }
    };
  }

  searchSongs(options = {}) {
    const page = toPositiveInteger(options.page, 1);
    const pageSize = Math.min(toPositiveInteger(options.pageSize, DEFAULT_PAGE_SIZE), MAX_PAGE_SIZE);
    const query = normalizeCatalogText(options.query);
    const artist = normalizeArtistName(options.artist);
    const title = normalizeCatalogText(options.title);

    let songs = this.getPublicSongs();

    if (query) {
      songs = songs.filter((song) => {
        const combined = `${song.normalizedArtist} ${song.normalizedTitle}`;
        return combined.includes(query);
      });
    }

    if (artist) {
      songs = songs.filter((song) => song.normalizedArtist.includes(artist));
    }

    if (title) {
      songs = songs.filter((song) => song.normalizedTitle.includes(title));
    }

    songs = songs.sort((left, right) => {
      const artistCompare = left.normalizedArtist.localeCompare(right.normalizedArtist);
      if (artistCompare !== 0) {
        return artistCompare;
      }

      return left.normalizedTitle.localeCompare(right.normalizedTitle);
    });

    const total = songs.length;
    const start = (page - 1) * pageSize;
    const items = songs.slice(start, start + pageSize).map((song) => this.toSongSummary(song));

    return {
      page,
      pageSize,
      total,
      hasNextPage: start + pageSize < total,
      items
    };
  }

  findExactMatch(artistName, title) {
    const normalizedArtist = normalizeArtistName(artistName);
    const normalizedTitle = normalizeCatalogText(title);

    if (!normalizedArtist || !normalizedTitle) {
      return null;
    }

    const song = this.getPublicSongs().find((candidate) => {
      return candidate.normalizedArtist === normalizedArtist && candidate.normalizedTitle === normalizedTitle;
    });

    return song ? this.toSongSummary(song) : null;
  }

  getSongDetail(songId) {
    const song = this.songsById.get(songId);

    if (!song || !isPublicSong(song)) {
      return null;
    }

    return {
      ...this.toSongSummary(song),
      mediaVersions: (song.media || [])
        .filter((media) => !media.retiredAt && media.reviewState === 'approved')
        .map((media) => this.toPublicMediaVersion(media))
    };
  }

  listAlternateVersions(songId, options = {}) {
    const page = toPositiveInteger(options.page, 1);
    const pageSize = Math.min(toPositiveInteger(options.pageSize, DEFAULT_PAGE_SIZE), MAX_PAGE_SIZE);
    const requestedSong = this.songsById.get(songId);
    if (!requestedSong || !isPublicSong(requestedSong)) {
      return {
        page,
        pageSize,
        total: 0,
        hasNextPage: false,
        items: []
      };
    }

    const relationships = (this.catalog.alternateVersions || []).filter((relationship) => {
      return !relationship.retiredAt && (relationship.songId === songId || relationship.alternateSongId === songId);
    });

    const items = relationships
      .map((relationship) => {
        const alternateSongId = relationship.songId === songId ? relationship.alternateSongId : relationship.songId;
        const alternateSong = this.songsById.get(alternateSongId);
        if (!alternateSong || !isPublicSong(alternateSong)) {
          return null;
        }

        return {
          relationshipId: relationship.relationshipId,
          relationshipType: relationship.relationshipType,
          alternateSong: this.toSongSummary(alternateSong)
        };
      })
      .filter(Boolean)
      .sort((left, right) => {
        const artistCompare = left.alternateSong.normalizedArtist.localeCompare(right.alternateSong.normalizedArtist);
        if (artistCompare !== 0) {
          return artistCompare;
        }

        return left.alternateSong.normalizedTitle.localeCompare(right.alternateSong.normalizedTitle);
      });

    const total = items.length;
    const start = (page - 1) * pageSize;
    return {
      page,
      pageSize,
      total,
      hasNextPage: start + pageSize < total,
      items: items.slice(start, start + pageSize)
    };
  }

  createSong(payload, auditContext = {}) {
    const now = new Date().toISOString();
    const songId = payload.songId || randomUUID();
    const media = (payload.mediaVersions || []).map((mediaVersion) => ({
      authorizedMediaId: mediaVersion.authorizedMediaId || randomUUID(),
      providerId: mediaVersion.providerId,
      providerTrackId: mediaVersion.providerTrackId || null,
      sha256Checksum: mediaVersion.sha256Checksum,
      fileSizeBytes: mediaVersion.fileSizeBytes,
      durationSeconds: mediaVersion.durationSeconds,
      fileFormat: mediaVersion.fileFormat,
      vocalGuideType: mediaVersion.vocalGuideType || 'unknown',
      storageRelativeKey: mediaVersion.storageRelativeKey,
      isPreferredVersion: Boolean(mediaVersion.isPreferredVersion),
      reviewState: mediaVersion.reviewState || 'pending_review',
      qualityRating: mediaVersion.qualityRating || null,
      authorizationNotes: mediaVersion.authorizationNotes || null,
      lastVerifiedAt: mediaVersion.lastVerifiedAt || null,
      createdAt: now,
      updatedAt: now,
      retiredAt: null,
      retirementReason: null
    }));
    const preferred = media.find((mediaVersion) => mediaVersion.isPreferredVersion);
    const song = {
      songId,
      title: payload.title,
      artistName: payload.artistName,
      normalizedTitle: normalizeCatalogText(payload.title),
      normalizedArtist: normalizeArtistName(payload.artistName),
      language: payload.language || 'und',
      preferredAuthorizedMediaId: preferred ? preferred.authorizedMediaId : null,
      reviewState: payload.reviewState || 'pending_review',
      qualityRating: payload.qualityRating || null,
      authorizationNotes: payload.authorizationNotes || null,
      lastVerifiedAt: payload.lastVerifiedAt || null,
      createdAt: now,
      updatedAt: now,
      retiredAt: null,
      retirementReason: null,
      media
    };

    this.catalog.songs.push(song);
    this.songsById.set(song.songId, song);
    this.recordAudit('song', song.songId, 'create', null, cloneJson(song), auditContext);
    return this.toAdminSong(song);
  }

  updateSong(songId, payload, auditContext = {}) {
    const song = this.requireSong(songId);
    const before = cloneJson(song);

    if (payload.title !== undefined) {
      song.title = payload.title;
      song.normalizedTitle = normalizeCatalogText(payload.title);
    }
    if (payload.artistName !== undefined) {
      song.artistName = payload.artistName;
      song.normalizedArtist = normalizeArtistName(payload.artistName);
    }
    if (payload.language !== undefined) {
      song.language = payload.language;
    }
    if (payload.qualityRating !== undefined) {
      song.qualityRating = payload.qualityRating;
    }
    if (payload.lastVerifiedAt !== undefined) {
      song.lastVerifiedAt = payload.lastVerifiedAt;
    }
    song.updatedAt = new Date().toISOString();

    this.recordAudit('song', song.songId, 'update', before, cloneJson(song), auditContext);
    return this.toAdminSong(song);
  }

  setPreferredVersion(songId, authorizedMediaId, auditContext = {}) {
    const song = this.requireSong(songId);
    const media = (song.media || []).find((mediaVersion) => mediaVersion.authorizedMediaId === authorizedMediaId);
    if (!media || media.retiredAt) {
      throw new CatalogOperationError('media_not_found', 'Authorized media version was not found for this song.', 404);
    }

    const before = cloneJson(song);
    for (const mediaVersion of song.media || []) {
      mediaVersion.isPreferredVersion = mediaVersion.authorizedMediaId === authorizedMediaId;
      mediaVersion.updatedAt = new Date().toISOString();
    }
    song.preferredAuthorizedMediaId = authorizedMediaId;
    song.updatedAt = new Date().toISOString();

    this.recordAudit('song', song.songId, 'set_preferred_version', before, cloneJson(song), auditContext);
    return this.toAdminSong(song);
  }

  setReviewState(songId, reviewState, auditContext = {}) {
    const song = this.requireSong(songId);
    const before = cloneJson(song);
    song.reviewState = reviewState;
    if (reviewState === 'retired' && !song.retiredAt) {
      song.retiredAt = new Date().toISOString();
    }
    song.updatedAt = new Date().toISOString();

    this.recordAudit('song', song.songId, 'set_review_state', before, cloneJson(song), auditContext);
    return this.toAdminSong(song);
  }

  updateSourceNotes(songId, authorizationNotes, auditContext = {}) {
    const song = this.requireSong(songId);
    const before = cloneJson(song);
    song.authorizationNotes = authorizationNotes || null;
    song.updatedAt = new Date().toISOString();

    this.recordAudit('song', song.songId, 'update_source_notes', before, cloneJson(song), auditContext);
    return this.toAdminSong(song);
  }

  retireSong(songId, retirementReason, auditContext = {}) {
    const song = this.requireSong(songId);
    const before = cloneJson(song);
    song.reviewState = 'retired';
    song.retiredAt = new Date().toISOString();
    song.retirementReason = retirementReason || 'Retired by temporary catalog admin.';
    song.updatedAt = song.retiredAt;

    this.recordAudit('song', song.songId, 'soft_retire', before, cloneJson(song), auditContext);
    return this.toAdminSong(song);
  }

  getAuditHistory(options = {}) {
    const page = toPositiveInteger(options.page, 1);
    const pageSize = Math.min(toPositiveInteger(options.pageSize, DEFAULT_PAGE_SIZE), MAX_PAGE_SIZE);
    let records = [...this.auditRecords];

    if (options.entityType) {
      records = records.filter((record) => record.entityType === options.entityType);
    }
    if (options.entityId) {
      records = records.filter((record) => record.entityId === options.entityId);
    }

    records = records.sort((left, right) => right.createdAt.localeCompare(left.createdAt));
    const total = records.length;
    const start = (page - 1) * pageSize;

    return {
      page,
      pageSize,
      total,
      hasNextPage: start + pageSize < total,
      items: records.slice(start, start + pageSize)
    };
  }

  registerHostDevice(payload = {}) {
    const now = new Date().toISOString();
    const hostDeviceId = payload.hostDeviceId || randomUUID();
    const existing = this.hostDevicesById.get(hostDeviceId) || {};
    const syncState = payload.syncState || (payload.interruptedSyncState || payload.interruptedSync ? 'interrupted' : 'idle');
    const hostDevice = {
      ...existing,
      hostDeviceId,
      displayName: payload.displayName || existing.displayName,
      venueLabel: payload.venueLabel === undefined ? existing.venueLabel || null : payload.venueLabel || null,
      appVersion: payload.appVersion === undefined ? existing.appVersion || null : payload.appVersion || null,
      localFreeSpaceBytes: payload.localFreeSpaceBytes === undefined ? existing.localFreeSpaceBytes || null : payload.localFreeSpaceBytes,
      localLibraryRoot: payload.localLibraryRoot === undefined ? existing.localLibraryRoot || null : payload.localLibraryRoot || null,
      lastSeenAt: now,
      isActive: payload.isActive === undefined ? true : Boolean(payload.isActive),
      syncState,
      interruptedSyncState: syncState === 'interrupted'
        ? normalizeInterruptedSyncState(payload.interruptedSyncState || payload.interruptedSync)
        : null,
      createdAt: existing.createdAt || now,
      updatedAt: now
    };

    this.hostDevicesById.set(hostDeviceId, hostDevice);
    this.catalog.hostDevices = Array.from(this.hostDevicesById.values());
    return toSafeHostDevice(hostDevice);
  }

  updateHostHeartbeat(hostDeviceId, payload = {}) {
    const hostDevice = this.requireHostDevice(hostDeviceId);
    const now = new Date().toISOString();
    const syncState = payload.syncState || (payload.interruptedSyncState || payload.interruptedSync ? 'interrupted' : hostDevice.syncState || 'idle');

    if (payload.displayName !== undefined) hostDevice.displayName = payload.displayName;
    if (payload.venueLabel !== undefined) hostDevice.venueLabel = payload.venueLabel || null;
    if (payload.appVersion !== undefined) hostDevice.appVersion = payload.appVersion || null;
    if (payload.localFreeSpaceBytes !== undefined) hostDevice.localFreeSpaceBytes = payload.localFreeSpaceBytes;
    if (payload.localLibraryRoot !== undefined) hostDevice.localLibraryRoot = payload.localLibraryRoot || null;
    if (payload.isActive !== undefined) hostDevice.isActive = Boolean(payload.isActive);
    hostDevice.syncState = syncState;
    hostDevice.interruptedSyncState = syncState === 'interrupted'
      ? normalizeInterruptedSyncState(payload.interruptedSyncState || payload.interruptedSync || hostDevice.interruptedSyncState)
      : null;
    hostDevice.lastSeenAt = now;
    hostDevice.updatedAt = now;

    return toSafeHostDevice(hostDevice);
  }

  listHostStatuses(options = {}) {
    const page = toPositiveInteger(options.page, 1);
    const pageSize = Math.min(toPositiveInteger(options.pageSize, DEFAULT_PAGE_SIZE), MAX_PAGE_SIZE);
    const hosts = Array.from(this.hostDevicesById.values())
      .map(toSafeHostDevice)
      .sort((left, right) => {
        if (left.isActive !== right.isActive) {
          return left.isActive ? -1 : 1;
        }
        return (right.lastSeenAt || '').localeCompare(left.lastSeenAt || '') ||
          left.displayName.localeCompare(right.displayName);
      });
    const total = hosts.length;
    const start = (page - 1) * pageSize;

    return {
      page,
      pageSize,
      total,
      hasNextPage: start + pageSize < total,
      items: hosts.slice(start, start + pageSize)
    };
  }

  createHostManifest(hostDeviceId) {
    const hostDevice = this.requireHostDevice(hostDeviceId);
    const mediaRecords = [];

    for (const song of this.getPublicSongs()) {
      for (const media of song.media || []) {
        if (media.retiredAt || media.reviewState !== 'approved') {
          continue;
        }

        mediaRecords.push({
          songId: song.songId,
          authorizedMediaId: media.authorizedMediaId,
          sha256Checksum: media.sha256Checksum,
          fileSizeBytes: media.fileSizeBytes,
          songUpdatedAt: song.updatedAt,
          mediaUpdatedAt: media.updatedAt,
          syncManifestPriority: media.syncManifestPriority,
          alwaysKeepOnHost: media.alwaysKeepOnHost,
          serverArchiveOnly: media.serverArchiveOnly,
          selectedHostDeviceIds: media.selectedHostDeviceIds,
          requestedSongPriorityBoost: media.requestedSongPriorityBoost,
          recentlyUsedPriorityBoost: media.recentlyUsedPriorityBoost
        });
      }
    }

    return createHostSyncManifest({ hostDevice, mediaRecords });
  }

  diffHostManifest(hostDeviceId, currentEntries = []) {
    return diffHostSyncManifest(this.createHostManifest(hostDeviceId), currentEntries);
  }

  createHostSyncOperation(hostDeviceId, payload = {}) {
    this.requireHostDevice(hostDeviceId);
    const now = new Date().toISOString();
    const operation = {
      syncOperationId: payload.syncOperationId || randomUUID(),
      hostDeviceId,
      operationKind: payload.operationKind || 'sync',
      status: payload.status || 'pending',
      progress: normalizeObject(payload.progress, DEFAULT_SYNC_PROGRESS),
      capacityCheck: normalizeObject(payload.capacityCheck, DEFAULT_CAPACITY_CHECK),
      verification: normalizeObject(payload.verification, DEFAULT_VERIFICATION),
      quarantine: normalizeObject(payload.quarantine, DEFAULT_QUARANTINE),
      retryPolicy: normalizeObject(payload.retryPolicy, DEFAULT_RETRY_POLICY),
      lastError: payload.lastError ? normalizeObject(payload.lastError, {}) : null,
      pauseRequestedAt: payload.pauseRequestedAt || null,
      resumeRequestedAt: payload.resumeRequestedAt || null,
      cancelRequestedAt: payload.cancelRequestedAt || null,
      startedAt: payload.startedAt || null,
      completedAt: payload.completedAt || null,
      createdAt: now,
      updatedAt: now
    };

    this.hostSyncOperationsById.set(operation.syncOperationId, operation);
    this.catalog.hostSyncOperations = Array.from(this.hostSyncOperationsById.values());
    return toHostSyncOperation(operation);
  }

  updateHostSyncOperation(syncOperationId, payload = {}) {
    const operation = this.requireHostSyncOperation(syncOperationId);
    if (payload.status !== undefined) operation.status = payload.status;
    if (payload.progress !== undefined) operation.progress = normalizeObject(payload.progress, DEFAULT_SYNC_PROGRESS);
    if (payload.capacityCheck !== undefined) operation.capacityCheck = normalizeObject(payload.capacityCheck, DEFAULT_CAPACITY_CHECK);
    if (payload.verification !== undefined) operation.verification = normalizeObject(payload.verification, DEFAULT_VERIFICATION);
    if (payload.quarantine !== undefined) operation.quarantine = normalizeObject(payload.quarantine, DEFAULT_QUARANTINE);
    if (payload.retryPolicy !== undefined) operation.retryPolicy = normalizeObject(payload.retryPolicy, DEFAULT_RETRY_POLICY);
    if (payload.lastError !== undefined) operation.lastError = payload.lastError ? normalizeObject(payload.lastError, {}) : null;
    if (payload.pauseRequestedAt !== undefined) operation.pauseRequestedAt = payload.pauseRequestedAt || null;
    if (payload.resumeRequestedAt !== undefined) operation.resumeRequestedAt = payload.resumeRequestedAt || null;
    if (payload.cancelRequestedAt !== undefined) operation.cancelRequestedAt = payload.cancelRequestedAt || null;
    if (payload.startedAt !== undefined) operation.startedAt = payload.startedAt || null;
    if (payload.completedAt !== undefined) operation.completedAt = payload.completedAt || null;
    operation.updatedAt = new Date().toISOString();
    return toHostSyncOperation(operation);
  }

  listHostSyncOperations(hostDeviceId, options = {}) {
    this.requireHostDevice(hostDeviceId);
    const page = toPositiveInteger(options.page, 1);
    const pageSize = Math.min(toPositiveInteger(options.pageSize, DEFAULT_PAGE_SIZE), MAX_PAGE_SIZE);
    const items = Array.from(this.hostSyncOperationsById.values())
      .filter((operation) => operation.hostDeviceId === hostDeviceId)
      .sort((left, right) => right.updatedAt.localeCompare(left.updatedAt))
      .map(toHostSyncOperation);
    const total = items.length;
    const start = (page - 1) * pageSize;
    return { page, pageSize, total, hasNextPage: start + pageSize < total, items: items.slice(start, start + pageSize) };
  }

  queueHostSyncOperatorAction(hostDeviceId, payload = {}) {
    this.requireHostDevice(hostDeviceId);
    const now = new Date().toISOString();
    const action = {
      syncActionId: payload.syncActionId || randomUUID(),
      hostDeviceId,
      action: payload.action || 'sync_now',
      status: payload.status || 'queued',
      safetyMode: payload.safetyMode || 'plan_only',
      requestedBy: payload.requestedBy || null,
      requestedAt: payload.requestedAt || now,
      reason: payload.reason || null,
      payload: normalizeObject(payload.payload, {}),
      createdAt: now,
      updatedAt: now
    };

    this.hostSyncOperatorActionsById.set(action.syncActionId, action);
    this.catalog.hostSyncOperatorActions = Array.from(this.hostSyncOperatorActionsById.values());
    return toHostSyncOperatorAction(action);
  }

  listHostSyncOperatorActions(hostDeviceId, options = {}) {
    this.requireHostDevice(hostDeviceId);
    const page = toPositiveInteger(options.page, 1);
    const pageSize = Math.min(toPositiveInteger(options.pageSize, DEFAULT_PAGE_SIZE), MAX_PAGE_SIZE);
    const items = Array.from(this.hostSyncOperatorActionsById.values())
      .filter((action) => action.hostDeviceId === hostDeviceId)
      .sort((left, right) => right.requestedAt.localeCompare(left.requestedAt))
      .map(toHostSyncOperatorAction);
    const total = items.length;
    const start = (page - 1) * pageSize;
    return { page, pageSize, total, hasNextPage: start + pageSize < total, items: items.slice(start, start + pageSize) };
  }

  recordHostSyncQuarantine(hostDeviceId, payload = {}) {
    this.requireHostDevice(hostDeviceId);
    const now = new Date().toISOString();
    const quarantine = {
      syncQuarantineId: payload.syncQuarantineId || randomUUID(),
      hostDeviceId,
      syncOperationId: payload.syncOperationId || null,
      authorizedMediaId: payload.authorizedMediaId || null,
      reason: payload.reason || 'verification_failed',
      verification: normalizeObject(payload.verification, {}),
      quarantineKey: payload.quarantineKey || 'planned-quarantine-entry',
      createdAt: now,
      resolvedAt: payload.resolvedAt || null
    };

    this.hostSyncQuarantineById.set(quarantine.syncQuarantineId, quarantine);
    this.catalog.hostSyncQuarantine = Array.from(this.hostSyncQuarantineById.values());
    return toHostSyncQuarantine(quarantine);
  }

  listHostSyncQuarantine(hostDeviceId, options = {}) {
    this.requireHostDevice(hostDeviceId);
    const page = toPositiveInteger(options.page, 1);
    const pageSize = Math.min(toPositiveInteger(options.pageSize, DEFAULT_PAGE_SIZE), MAX_PAGE_SIZE);
    const items = Array.from(this.hostSyncQuarantineById.values())
      .filter((quarantine) => quarantine.hostDeviceId === hostDeviceId)
      .sort((left, right) => right.createdAt.localeCompare(left.createdAt))
      .map(toHostSyncQuarantine);
    const total = items.length;
    const start = (page - 1) * pageSize;
    return { page, pageSize, total, hasNextPage: start + pageSize < total, items: items.slice(start, start + pageSize) };
  }

  getPublicSongs() {
    return (this.catalog.songs || []).filter(isPublicSong);
  }

  toSongSummary(song) {
    return {
      songId: song.songId,
      title: song.title,
      artistName: song.artistName,
      normalizedTitle: song.normalizedTitle,
      normalizedArtist: song.normalizedArtist,
      language: song.language,
      preferredAuthorizedMediaId: song.preferredAuthorizedMediaId,
      reviewState: song.reviewState,
      qualityRating: song.qualityRating,
      lastVerifiedAt: song.lastVerifiedAt,
      updatedAt: song.updatedAt
    };
  }

  toAdminSong(song) {
    return {
      ...this.toSongSummary(song),
      authorizationNotes: song.authorizationNotes || null,
      retiredAt: song.retiredAt || null,
      retirementReason: song.retirementReason || null
    };
  }

  toPublicMediaVersion(media) {
    const provider = this.providersById.get(media.providerId);

    return {
      authorizedMediaId: media.authorizedMediaId,
      providerId: media.providerId,
      providerName: provider ? provider.displayName : 'Unknown provider',
      providerTrackId: media.providerTrackId,
      fileFormat: media.fileFormat,
      vocalGuideType: media.vocalGuideType,
      durationSeconds: media.durationSeconds,
      fileSizeBytes: media.fileSizeBytes,
      isPreferredVersion: media.isPreferredVersion,
      qualityRating: media.qualityRating,
      lastVerifiedAt: media.lastVerifiedAt
    };
  }

  requireSong(songId) {
    const song = this.songsById.get(songId);
    if (!song) {
      throw new CatalogOperationError('song_not_found', 'Song was not found.', 404);
    }

    return song;
  }

  requireHostDevice(hostDeviceId) {
    const hostDevice = this.hostDevicesById.get(hostDeviceId);
    if (!hostDevice) {
      throw new CatalogOperationError('host_device_not_found', 'Host device was not found.', 404);
    }

    return hostDevice;
  }

  requireHostSyncOperation(syncOperationId) {
    const operation = this.hostSyncOperationsById.get(syncOperationId);
    if (!operation) {
      throw new CatalogOperationError('host_sync_operation_not_found', 'Host sync operation was not found.', 404);
    }

    return operation;
  }

  recordAudit(entityType, entityId, action, beforeSnapshot, afterSnapshot, auditContext) {
    this.auditRecords.push({
      auditId: randomUUID(),
      entityType,
      entityId,
      action,
      actorLabel: auditContext.actorLabel || 'temporary-admin',
      changeReason: auditContext.changeReason || null,
      beforeSnapshot,
      afterSnapshot,
      createdAt: new Date().toISOString()
    });
  }
}

function isPublicSong(song) {
  return !song.retiredAt && song.reviewState === 'approved';
}

function toPositiveInteger(value, fallback) {
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed) || parsed < 1) {
    return fallback;
  }

  return parsed;
}

const DEFAULT_SYNC_PROGRESS = Object.freeze({
  totalEntries: 0,
  completedEntries: 0,
  pendingEntries: 0,
  failedEntries: 0,
  bytesTotal: 0,
  bytesCompleted: 0,
  percentComplete: 0
});
const DEFAULT_CAPACITY_CHECK = Object.freeze({ localFreeSpaceBytes: null, requiredBytes: 0, isSufficient: true });
const DEFAULT_VERIFICATION = Object.freeze({ checksumAlgorithm: 'sha256', result: 'not_checked' });
const DEFAULT_QUARANTINE = Object.freeze({ required: false });
const DEFAULT_RETRY_POLICY = Object.freeze({ attempt: 0, maxAttempts: 0, nextRetryAt: null, backoffSeconds: 0 });

function normalizeObject(value, fallback) {
  if (value === undefined || value === null) {
    return cloneJson(fallback);
  }
  if (typeof value !== 'object' || Array.isArray(value)) {
    throw new CatalogOperationError('invalid_sync_control_metadata', 'Sync control metadata must be a JSON object.', 400);
  }
  return cloneJson(value);
}

function toHostSyncOperation(operation) {
  return cloneJson(operation);
}

function toHostSyncOperatorAction(action) {
  return cloneJson(action);
}

function toHostSyncQuarantine(quarantine) {
  return cloneJson(quarantine);
}

function cloneJson(value) {
  return JSON.parse(JSON.stringify(value));
}

class CatalogOperationError extends Error {
  constructor(code, message, statusCode = 400) {
    super(message);
    this.code = code;
    this.statusCode = statusCode;
  }
}

module.exports = {
  CatalogOperationError,
  CatalogRepository
};
