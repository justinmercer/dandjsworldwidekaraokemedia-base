const http = require('node:http');
const { randomUUID, timingSafeEqual } = require('node:crypto');
const { CatalogOperationError, CatalogRepository } = require('./catalogRepository');
const { loadDemoCatalog } = require('./catalogData');
const { HOST_SYNC_STATES } = require('./hostSync');

const MAX_BODY_BYTES = 64 * 1024;
const REVIEW_STATES = new Set(['pending_review', 'approved', 'rejected', 'needs_metadata', 'retired']);
const MEDIA_FORMATS = new Set(['cdg_mp3_bundle', 'mp4_karaoke', 'webm_karaoke', 'zip_bundle', 'other']);
const VOCAL_GUIDE_TYPES = new Set(['none', 'guide_vocal', 'background_vocals', 'duet', 'unknown']);
const HOST_SYNC_ACTIONS = new Set([
  'sync_now',
  'verify_library',
  'view_missing_locally',
  'review_cleanup_candidates',
  'pause_sync',
  'resume_sync',
  'cancel_pending_noncritical'
]);
const HOST_SYNC_OPERATION_STATUSES = new Set(['ready', 'pending', 'syncing', 'verified', 'failed', 'review_needed', 'paused', 'cancelled']);
const HOST_SYNC_SAFETY_MODES = new Set(['plan_only', 'metadata_only']);
const HOST_SYNC_ACTION_ALIASES = new Map([
  ['sync-now', 'sync_now'],
  ['verify-library', 'verify_library'],
  ['view-missing-locally', 'view_missing_locally'],
  ['review-cleanup-candidates', 'review_cleanup_candidates'],
  ['pause', 'pause_sync'],
  ['resume', 'resume_sync'],
  ['cancel-pending-noncritical', 'cancel_pending_noncritical']
]);

function createCatalogServer(options = {}) {
  const repository = options.repository || new CatalogRepository(options.catalog || loadDemoCatalog());
  const adminCredential = options.adminCredential || null;
  const hostRegistrationCredential = options.hostRegistrationCredential || null;
  const publicSearchLimiter = createPublicSearchLimiter(options.publicSearchRateLimit);

  return http.createServer(async (request, response) => {
    const correlationId = request.headers['x-correlation-id'] || randomUUID();
    response.setHeader('x-correlation-id', correlationId);

    try {
      await routeRequest(request, response, {
        adminCredential,
        correlationId,
        hostRegistrationCredential,
        publicSearchLimiter,
        repository
      });
    } catch (error) {
      const safeError = toSafeHttpError(error);
      writeJson(response, safeError.statusCode, {
        error: {
          code: safeError.code,
          message: safeError.message,
          correlationId
        }
      });
    }
  });
}

async function routeRequest(request, response, context) {
  const requestUrl = new URL(request.url, 'http://localhost');
  const pathname = requestUrl.pathname.replace(/\/+$/, '') || '/';
  const { repository } = context;

  if (isPublicCatalogPath(pathname) && request.method !== 'GET') {
    throw new HttpError(405, 'read_only_endpoint', 'Public catalog endpoints are read-only.');
  }

  if (request.method === 'GET' && (pathname === '/healthz' || pathname === '/api/catalog/healthz')) {
    writeJson(response, 200, await repository.getHealth());
    return;
  }

  if (request.method === 'GET' && pathname === '/api/catalog/search') {
    context.publicSearchLimiter.assertAllowed(getClientKey(request));
    writeJson(response, 200, await repository.searchSongs(Object.fromEntries(requestUrl.searchParams.entries())));
    return;
  }

  if (request.method === 'GET' && pathname === '/api/catalog/exact-match') {
    const match = await repository.findExactMatch(
      requestUrl.searchParams.get('artistName') || requestUrl.searchParams.get('artist'),
      requestUrl.searchParams.get('title')
    );

    writeJson(response, 200, { match });
    return;
  }

  const alternateMatch = pathname.match(/^\/api\/catalog\/songs\/([^/]+)\/alternate-versions$/);
  if (request.method === 'GET' && alternateMatch) {
    const result = await repository.listAlternateVersions(
      decodeURIComponent(alternateMatch[1]),
      Object.fromEntries(requestUrl.searchParams.entries())
    );
    writeJson(response, 200, result);
    return;
  }

  const songDetailMatch = pathname.match(/^\/api\/catalog\/songs\/([^/]+)$/);
  if (request.method === 'GET' && songDetailMatch) {
    const song = await repository.getSongDetail(decodeURIComponent(songDetailMatch[1]));
    if (!song) {
      throw new HttpError(404, 'song_not_found', 'Song was not found in the public catalog.');
    }

    writeJson(response, 200, { song });
    return;
  }

  if (pathname.startsWith('/api/admin/catalog')) {
    await routeAdminRequest(request, response, requestUrl, pathname, context);
    return;
  }

  if (pathname.startsWith('/api/admin/hosts')) {
    await routeAdminHostsRequest(request, response, requestUrl, pathname, context);
    return;
  }

  if (pathname.startsWith('/api/host')) {
    await routeHostRequest(request, response, requestUrl, pathname, context);
    return;
  }

  throw new HttpError(404, 'not_found', 'Route was not found.');
}

async function routeAdminRequest(request, response, requestUrl, pathname, context) {
  const auditContext = requireAdminAuthorization(request, context.adminCredential);
  const { repository } = context;

  if (request.method === 'GET' && pathname === '/api/admin/catalog/audit') {
    writeJson(response, 200, await repository.getAuditHistory(Object.fromEntries(requestUrl.searchParams.entries())));
    return;
  }

  if (request.method === 'POST' && pathname === '/api/admin/catalog/songs') {
    const body = await readJsonBody(request);
    validateSongCreate(body);
    const song = await repository.createSong(body, auditContext);
    writeJson(response, 201, { song });
    return;
  }

  const songMatch = pathname.match(/^\/api\/admin\/catalog\/songs\/([^/]+)$/);
  if (request.method === 'PATCH' && songMatch) {
    const body = await readJsonBody(request);
    validateSongUpdate(body);
    const song = await repository.updateSong(decodeURIComponent(songMatch[1]), body, auditContext);
    writeJson(response, 200, { song });
    return;
  }

  const preferredMatch = pathname.match(/^\/api\/admin\/catalog\/songs\/([^/]+)\/preferred-version$/);
  if ((request.method === 'PUT' || request.method === 'PATCH') && preferredMatch) {
    const body = await readJsonBody(request);
    requireNonBlankString(body.authorizedMediaId, 'authorizedMediaId');
    const song = await repository.setPreferredVersion(
      decodeURIComponent(preferredMatch[1]),
      body.authorizedMediaId,
      auditContext
    );
    writeJson(response, 200, { song });
    return;
  }

  const reviewMatch = pathname.match(/^\/api\/admin\/catalog\/songs\/([^/]+)\/review-state$/);
  if (request.method === 'PATCH' && reviewMatch) {
    const body = await readJsonBody(request);
    validateReviewState(body.reviewState);
    const song = await repository.setReviewState(decodeURIComponent(reviewMatch[1]), body.reviewState, auditContext);
    writeJson(response, 200, { song });
    return;
  }

  const notesMatch = pathname.match(/^\/api\/admin\/catalog\/songs\/([^/]+)\/source-notes$/);
  if (request.method === 'PATCH' && notesMatch) {
    const body = await readJsonBody(request);
    validateOptionalString(body.authorizationNotes, 'authorizationNotes', 4000);
    const song = await repository.updateSourceNotes(
      decodeURIComponent(notesMatch[1]),
      body.authorizationNotes || null,
      auditContext
    );
    writeJson(response, 200, { song });
    return;
  }

  const retireMatch = pathname.match(/^\/api\/admin\/catalog\/songs\/([^/]+)\/retire$/);
  if ((request.method === 'POST' || request.method === 'PATCH') && retireMatch) {
    const body = await readJsonBody(request);
    validateOptionalString(body.retirementReason, 'retirementReason', 1000);
    const song = await repository.retireSong(
      decodeURIComponent(retireMatch[1]),
      body.retirementReason || null,
      auditContext
    );
    writeJson(response, 200, { song });
    return;
  }

  throw new HttpError(404, 'not_found', 'Route was not found.');
}

async function routeAdminHostsRequest(request, response, requestUrl, pathname, context) {
  const auditContext = requireAdminAuthorization(request, context.adminCredential);
  const { repository } = context;

  if (request.method === 'GET' && (pathname === '/api/admin/hosts' || pathname === '/api/admin/hosts/status')) {
    writeJson(response, 200, await repository.listHostStatuses(Object.fromEntries(requestUrl.searchParams.entries())));
    return;
  }

  const hostSyncMatch = pathname.match(/^\/api\/admin\/hosts\/([^/]+)\/sync\/([^/]+)(?:\/([^/]+))?$/);
  if (hostSyncMatch) {
    const hostDeviceId = decodeURIComponent(hostSyncMatch[1]);
    const syncResource = hostSyncMatch[2];
    const syncActionAlias = hostSyncMatch[3];

    if (request.method === 'GET' && syncResource === 'summary' && !syncActionAlias) {
      writeJson(response, 200, await repository.getHostSyncSummary(hostDeviceId));
      return;
    }

    if (request.method === 'GET' && syncResource === 'operations' && !syncActionAlias) {
      writeJson(response, 200, await repository.listHostSyncOperations(hostDeviceId, Object.fromEntries(requestUrl.searchParams.entries())));
      return;
    }

    if (request.method === 'POST' && syncResource === 'operations' && !syncActionAlias) {
      const body = await readJsonBody(request);
      validateHostSyncOperationCreate(body);
      writeJson(response, 201, { operation: await repository.createHostSyncOperation(hostDeviceId, body) });
      return;
    }

    if (request.method === 'PATCH' && syncResource === 'operations' && syncActionAlias) {
      const body = await readJsonBody(request);
      validateHostSyncOperationUpdate(body);
      writeJson(response, 200, { operation: await repository.updateHostSyncOperation(decodeURIComponent(syncActionAlias), body) });
      return;
    }

    if (request.method === 'GET' && syncResource === 'actions' && !syncActionAlias) {
      writeJson(response, 200, await repository.listHostSyncOperatorActions(hostDeviceId, Object.fromEntries(requestUrl.searchParams.entries())));
      return;
    }

    if (request.method === 'POST' && syncResource === 'actions' && !syncActionAlias) {
      const body = await readJsonBody(request);
      validateHostSyncOperatorAction(body);
      writeJson(response, 202, { action: await repository.queueHostSyncOperatorAction(hostDeviceId, withAdminActionContext(body, auditContext)) });
      return;
    }

    if (request.method === 'POST' && syncResource === 'actions' && syncActionAlias) {
      const action = HOST_SYNC_ACTION_ALIASES.get(syncActionAlias);
      if (!action) {
        throw new HttpError(404, 'not_found', 'Sync action route was not found.');
      }
      const body = await readJsonBody(request);
      validateHostSyncOperatorAction({ ...body, action });
      writeJson(response, 202, { action: await repository.queueHostSyncOperatorAction(hostDeviceId, withAdminActionContext({ ...body, action }, auditContext)) });
      return;
    }

    if (request.method === 'GET' && syncResource === 'quarantine' && !syncActionAlias) {
      writeJson(response, 200, await repository.listHostSyncQuarantine(hostDeviceId, Object.fromEntries(requestUrl.searchParams.entries())));
      return;
    }

    if (request.method === 'POST' && syncResource === 'quarantine' && !syncActionAlias) {
      const body = await readJsonBody(request);
      validateHostSyncQuarantine(body);
      writeJson(response, 201, { quarantine: await repository.recordHostSyncQuarantine(hostDeviceId, body) });
      return;
    }
  }

  throw new HttpError(404, 'not_found', 'Route was not found.');
}

async function routeHostRequest(request, response, requestUrl, pathname, context) {
  requireHostRegistrationAuthorization(request, context.hostRegistrationCredential);
  const { repository } = context;

  if (request.method === 'POST' && pathname === '/api/host/register') {
    const body = await readJsonBody(request);
    validateHostRegistration(body);
    const hostDevice = await repository.registerHostDevice(body);
    writeJson(response, 201, { hostDevice });
    return;
  }

  if (request.method === 'POST' && pathname === '/api/host/heartbeat') {
    const body = await readJsonBody(request);
    validateHostHeartbeat(body);
    const hostDevice = await repository.updateHostHeartbeat(body.hostDeviceId, body);
    writeJson(response, 200, { hostDevice });
    return;
  }

  if (request.method === 'GET' && pathname === '/api/host/manifest') {
    const hostDeviceId = requireSearchParam(requestUrl, 'hostDeviceId');
    writeJson(response, 200, await repository.createHostManifest(hostDeviceId));
    return;
  }

  if (request.method === 'POST' && pathname === '/api/host/manifest/diff') {
    const body = await readJsonBody(request);
    validateManifestDiffRequest(body);
    writeJson(response, 200, await repository.diffHostManifest(body.hostDeviceId, body.currentEntries || []));
    return;
  }

  throw new HttpError(404, 'not_found', 'Route was not found.');
}

function requireAdminAuthorization(request, adminCredential) {
  if (!adminCredential) {
    throw new HttpError(503, 'admin_auth_not_configured', 'Catalog management is not configured.');
  }

  const presented = getPresentedAdminToken(request);
  if (!presented || !safeTokenEquals(presented, adminCredential)) {
    throw new HttpError(401, 'admin_unauthorized', 'Admin authorization is required.');
  }

  return {
    actorLabel: sanitizeAuditLabel(request.headers['x-admin-actor']) || 'temporary-admin',
    changeReason: sanitizeAuditLabel(request.headers['x-change-reason']) || null
  };
}

function requireHostRegistrationAuthorization(request, hostRegistrationCredential) {
  if (!hostRegistrationCredential) {
    throw new HttpError(503, 'host_registration_not_configured', 'Host registration is not configured.');
  }

  const presented = getPresentedHostRegistrationToken(request);
  if (!presented || !safeTokenEquals(presented, hostRegistrationCredential)) {
    throw new HttpError(401, 'host_unauthorized', 'Host registration authorization is required.');
  }
}

function getPresentedHostRegistrationToken(request) {
  const authorization = request.headers.authorization || '';
  const bearerMatch = authorization.match(/^Bearer\s+(.+)$/i);
  if (bearerMatch) {
    return bearerMatch[1];
  }

  return request.headers['x-hq-host-registration-token'] || null;
}

function getPresentedAdminToken(request) {
  const authorization = request.headers.authorization || '';
  const bearerMatch = authorization.match(/^Bearer\s+(.+)$/i);
  if (bearerMatch) {
    return bearerMatch[1];
  }

  return request.headers['x-hq-admin-token'] || null;
}

function safeTokenEquals(left, right) {
  const leftBuffer = Buffer.from(String(left));
  const rightBuffer = Buffer.from(String(right));
  if (leftBuffer.length !== rightBuffer.length) {
    return false;
  }

  return timingSafeEqual(leftBuffer, rightBuffer);
}

function sanitizeAuditLabel(value) {
  const label = Array.isArray(value) ? value[0] : value;
  return String(label || '').replace(/[^a-zA-Z0-9_.:@ -]/g, '').trim().slice(0, 120);
}

async function readJsonBody(request) {
  const chunks = [];
  let size = 0;

  for await (const chunk of request) {
    size += chunk.length;
    if (size > MAX_BODY_BYTES) {
      throw new HttpError(413, 'request_too_large', 'Request body is too large.');
    }
    chunks.push(chunk);
  }

  const raw = Buffer.concat(chunks).toString('utf8').trim();
  if (!raw) {
    return {};
  }

  try {
    return JSON.parse(raw);
  } catch {
    throw new HttpError(400, 'invalid_json', 'Request body must be valid JSON.');
  }
}

function validateSongCreate(body) {
  requireObject(body);
  requireNonBlankString(body.title, 'title');
  requireNonBlankString(body.artistName, 'artistName');
  validateOptionalString(body.language, 'language', 12);
  validateReviewState(body.reviewState, true);
  validateQualityRating(body.qualityRating);
  validateOptionalString(body.authorizationNotes, 'authorizationNotes', 4000);
  validateMediaVersions(body.mediaVersions);
}

function validateSongUpdate(body) {
  requireObject(body);
  const allowed = ['title', 'artistName', 'language', 'qualityRating', 'lastVerifiedAt'];
  if (!allowed.some((key) => body[key] !== undefined)) {
    throw new HttpError(400, 'validation_failed', 'At least one updatable song field is required.');
  }

  validateOptionalString(body.title, 'title', 500);
  validateOptionalString(body.artistName, 'artistName', 500);
  validateOptionalString(body.language, 'language', 12);
  validateOptionalString(body.lastVerifiedAt, 'lastVerifiedAt', 64);
  validateQualityRating(body.qualityRating);
}

function validateHostRegistration(body) {
  requireObject(body);
  validateOptionalString(body.hostDeviceId, 'hostDeviceId', 120);
  validateOptionalString(body.displayName, 'displayName', 120, true);
  validateOptionalString(body.venueLabel, 'venueLabel', 120);
  validateOptionalString(body.appVersion, 'appVersion', 80);
  validateOptionalNonNegativeInteger(body.localFreeSpaceBytes, 'localFreeSpaceBytes');
  validateOptionalString(body.localLibraryRoot, 'localLibraryRoot', 500);
  validateOptionalBoolean(body.isActive, 'isActive');
  validateOptionalHostSyncState(body.syncState);
  validateInterruptedSyncState(body.interruptedSyncState || body.interruptedSync);
}

function validateHostHeartbeat(body) {
  requireObject(body);
  validateOptionalString(body.hostDeviceId, 'hostDeviceId', 120, true);
  validateOptionalString(body.displayName, 'displayName', 120);
  validateOptionalString(body.venueLabel, 'venueLabel', 120);
  validateOptionalString(body.appVersion, 'appVersion', 80);
  validateOptionalNonNegativeInteger(body.localFreeSpaceBytes, 'localFreeSpaceBytes');
  validateOptionalString(body.localLibraryRoot, 'localLibraryRoot', 500);
  validateOptionalBoolean(body.isActive, 'isActive');
  validateOptionalHostSyncState(body.syncState);
  validateInterruptedSyncState(body.interruptedSyncState || body.interruptedSync);
}

function validateHostSyncOperationCreate(body) {
  requireObject(body);
  validateOptionalString(body.syncOperationId, 'syncOperationId', 120);
  validateOptionalString(body.operationKind, 'operationKind', 80);
  validateOptionalEnum(body.status, 'status', HOST_SYNC_OPERATION_STATUSES);
  validateOptionalObject(body.progress, 'progress');
  validateOptionalObject(body.capacityCheck, 'capacityCheck');
  validateOptionalObject(body.verification, 'verification');
  validateOptionalObject(body.quarantine, 'quarantine');
  validateOptionalObject(body.retryPolicy, 'retryPolicy');
  validateOptionalObject(body.lastError, 'lastError');
  validateOptionalString(body.pauseRequestedAt, 'pauseRequestedAt', 80);
  validateOptionalString(body.resumeRequestedAt, 'resumeRequestedAt', 80);
  validateOptionalString(body.cancelRequestedAt, 'cancelRequestedAt', 80);
  validateOptionalString(body.startedAt, 'startedAt', 80);
  validateOptionalString(body.completedAt, 'completedAt', 80);
}

function validateHostSyncOperationUpdate(body) {
  validateHostSyncOperationCreate(body);
}

function validateHostSyncOperatorAction(body) {
  requireObject(body);
  validateOptionalString(body.syncActionId, 'syncActionId', 120);
  requireEnum(body.action || 'sync_now', 'action', HOST_SYNC_ACTIONS);
  validateOptionalEnum(body.safetyMode, 'safetyMode', HOST_SYNC_SAFETY_MODES);
  validateOptionalString(body.requestedBy, 'requestedBy', 160);
  validateOptionalString(body.requestedAt, 'requestedAt', 80);
  validateOptionalString(body.reason, 'reason', 500);
  validateOptionalObject(body.payload, 'payload');
}

function validateHostSyncQuarantine(body) {
  requireObject(body);
  validateOptionalString(body.syncQuarantineId, 'syncQuarantineId', 120);
  validateOptionalString(body.syncOperationId, 'syncOperationId', 120);
  validateOptionalString(body.authorizedMediaId, 'authorizedMediaId', 120);
  validateOptionalString(body.reason, 'reason', 500);
  validateOptionalObject(body.verification, 'verification');
  validateOptionalString(body.quarantineKey, 'quarantineKey', 240);
  validateOptionalString(body.resolvedAt, 'resolvedAt', 80);
}

function validateManifestDiffRequest(body) {
  requireObject(body);
  validateOptionalString(body.hostDeviceId, 'hostDeviceId', 120, true);
  if (body.currentEntries === undefined) {
    return;
  }
  if (!Array.isArray(body.currentEntries)) {
    throw new HttpError(400, 'validation_failed', 'currentEntries must be an array.');
  }
  for (const entry of body.currentEntries) {
    requireObject(entry);
    validateOptionalString(entry.songId, 'songId', 120);
    validateOptionalString(entry.authorizedMediaId, 'authorizedMediaId', 120);
    validateOptionalString(entry.mediaKey, 'mediaKey', 180);
    validateOptionalString(entry.versionTimestamp, 'versionTimestamp', 80);
    validateOptionalNonNegativeInteger(entry.fileSizeBytes, 'fileSizeBytes');
    validateOptionalString(entry.sha256Checksum, 'sha256Checksum', 64);
    if (entry.sha256Checksum !== undefined && !/^[0-9a-f]{64}$/.test(entry.sha256Checksum)) {
      throw new HttpError(400, 'validation_failed', 'sha256Checksum must be lowercase 64-character hex.');
    }
  }
}

function validateMediaVersions(mediaVersions) {
  if (mediaVersions === undefined) {
    return;
  }
  if (!Array.isArray(mediaVersions)) {
    throw new HttpError(400, 'validation_failed', 'mediaVersions must be an array.');
  }

  let preferredCount = 0;
  for (const mediaVersion of mediaVersions) {
    requireObject(mediaVersion);
    requireNonBlankString(mediaVersion.providerId, 'providerId');
    requireNonBlankString(mediaVersion.sha256Checksum, 'sha256Checksum');
    requirePositiveInteger(mediaVersion.fileSizeBytes, 'fileSizeBytes');
    requirePositiveInteger(mediaVersion.durationSeconds, 'durationSeconds');
    requireEnum(mediaVersion.fileFormat, 'fileFormat', MEDIA_FORMATS);
    validateOptionalEnum(mediaVersion.vocalGuideType, 'vocalGuideType', VOCAL_GUIDE_TYPES);
    requireNonBlankString(mediaVersion.storageRelativeKey, 'storageRelativeKey');
    validateStorageRelativeKey(mediaVersion.storageRelativeKey);
    validateReviewState(mediaVersion.reviewState, true);
    validateQualityRating(mediaVersion.qualityRating);
    validateOptionalString(mediaVersion.authorizationNotes, 'authorizationNotes', 4000);
    validateOptionalString(mediaVersion.providerTrackId, 'providerTrackId', 200);

    if (!/^[0-9a-f]{64}$/.test(mediaVersion.sha256Checksum)) {
      throw new HttpError(400, 'validation_failed', 'sha256Checksum must be lowercase 64-character hex.');
    }
    if (mediaVersion.isPreferredVersion) {
      preferredCount += 1;
    }
  }

  if (preferredCount > 1) {
    throw new HttpError(400, 'validation_failed', 'Only one media version can be preferred.');
  }
}

function requireObject(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(400, 'validation_failed', 'Request body must be a JSON object.');
  }
}

function requireNonBlankString(value, field) {
  if (typeof value !== 'string' || value.trim() === '') {
    throw new HttpError(400, 'validation_failed', `${field} is required.`);
  }
}

function validateOptionalString(value, field, maxLength, required = false) {
  if (value === undefined || value === null) {
    if (required) {
      throw new HttpError(400, 'validation_failed', `${field} is required.`);
    }
    return;
  }
  if (typeof value !== 'string' || value.trim() === '') {
    throw new HttpError(400, 'validation_failed', `${field} must be a non-empty string.`);
  }
  if (value.length > maxLength) {
    throw new HttpError(400, 'validation_failed', `${field} is too long.`);
  }
}

function validateReviewState(value, optional = false) {
  if (value === undefined || value === null) {
    if (optional) {
      return;
    }
    throw new HttpError(400, 'validation_failed', 'reviewState is required.');
  }
  requireEnum(value, 'reviewState', REVIEW_STATES);
}

function validateOptionalEnum(value, field, values) {
  if (value === undefined || value === null) {
    return;
  }
  requireEnum(value, field, values);
}

function validateOptionalHostSyncState(value) {
  if (value === undefined || value === null) {
    return;
  }
  requireEnum(value, 'syncState', HOST_SYNC_STATES);
}

function validateInterruptedSyncState(value) {
  if (value === undefined || value === null) {
    return;
  }
  requireObject(value);
  validateOptionalString(value.syncId, 'interruptedSyncState.syncId', 120);
  validateOptionalString(value.reason, 'interruptedSyncState.reason', 240);
  validateOptionalString(value.lastMediaKey, 'interruptedSyncState.lastMediaKey', 180);
  validateOptionalString(value.interruptedAt, 'interruptedSyncState.interruptedAt', 80);
}

function requireEnum(value, field, values) {
  if (!values.has(value)) {
    throw new HttpError(400, 'validation_failed', `${field} is not supported.`);
  }
}

function validateQualityRating(value) {
  if (value === undefined || value === null) {
    return;
  }
  if (!Number.isInteger(value) || value < 1 || value > 5) {
    throw new HttpError(400, 'validation_failed', 'qualityRating must be an integer between 1 and 5.');
  }
}

function requirePositiveInteger(value, field) {
  if (!Number.isInteger(value) || value < 1) {
    throw new HttpError(400, 'validation_failed', `${field} must be a positive integer.`);
  }
}

function validateOptionalNonNegativeInteger(value, field) {
  if (value === undefined || value === null) {
    return;
  }
  if (!Number.isInteger(value) || value < 0) {
    throw new HttpError(400, 'validation_failed', `${field} must be a non-negative integer.`);
  }
}

function validateOptionalObject(value, field) {
  if (value === undefined || value === null) {
    return;
  }
  if (typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(400, 'validation_failed', `${field} must be a JSON object.`);
  }
}

function withAdminActionContext(body, auditContext) {
  return {
    ...body,
    requestedBy: body.requestedBy || auditContext.actorLabel || 'temporary-admin'
  };
}

function validateOptionalBoolean(value, field) {
  if (value === undefined || value === null) {
    return;
  }
  if (typeof value !== 'boolean') {
    throw new HttpError(400, 'validation_failed', `${field} must be a boolean.`);
  }
}

function validateStorageRelativeKey(value) {
  if (/^\/|^[A-Za-z]:|^\\\\|(^|\/)\.\.(\/|$)/.test(value)) {
    throw new HttpError(400, 'validation_failed', 'storageRelativeKey must be relative and opaque.');
  }
}

function createPublicSearchLimiter(options = {}) {
  const max = options.max || 60;
  const windowMs = options.windowMs || 60_000;
  const buckets = new Map();

  return {
    assertAllowed(key) {
      const now = Date.now();
      const bucket = buckets.get(key);
      if (!bucket || now >= bucket.resetAt) {
        buckets.set(key, { count: 1, resetAt: now + windowMs });
        return;
      }

      bucket.count += 1;
      if (bucket.count > max) {
        throw new HttpError(429, 'rate_limited', 'Too many public catalog search requests.');
      }
    }
  };
}

function getClientKey(request) {
  const forwardedFor = request.headers['x-forwarded-for'];
  if (forwardedFor) {
    return String(forwardedFor).split(',')[0].trim();
  }

  return request.socket.remoteAddress || 'unknown';
}

function requireSearchParam(requestUrl, name) {
  const value = requestUrl.searchParams.get(name);
  if (!value) {
    throw new HttpError(400, 'validation_failed', `${name} is required.`);
  }

  return value;
}

function isPublicCatalogPath(pathname) {
  return pathname === '/healthz' || pathname.startsWith('/api/catalog');
}

function toSafeHttpError(error) {
  if (error instanceof HttpError) {
    return error;
  }
  if (error instanceof CatalogOperationError) {
    return new HttpError(error.statusCode || 400, error.code || 'catalog_operation_failed', error.message);
  }

  return new HttpError(500, 'internal_error', 'Catalog request failed.');
}

function writeJson(response, statusCode, payload) {
  response.writeHead(statusCode, {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store'
  });
  response.end(`${JSON.stringify(payload)}\n`);
}

class HttpError extends Error {
  constructor(statusCode, code, message) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
  }
}

module.exports = {
  createCatalogServer
};
