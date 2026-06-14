const { randomUUID } = require('node:crypto');
const { CatalogOperationError } = require('./catalogRepository');
const { normalizeArtistName, normalizeCatalogText } = require('./normalization');

let Pool;

const DEFAULT_PAGE_SIZE = 20;
const MAX_PAGE_SIZE = 50;

class PostgresCatalogRepository {
  constructor(options = {}) {
    if (!options.databaseUrl) {
      throw new Error('DATABASE_URL is required for PostgreSQL catalog mode.');
    }

    Pool = Pool || require('pg').Pool;
    this.pool = options.pool || new Pool({ connectionString: options.databaseUrl });
  }

  async close() {
    await this.pool.end();
  }

  async getHealth() {
    const { rows } = await this.pool.query(`
      SELECT
        (SELECT count(*)::int FROM hq_catalog.songs WHERE retired_at IS NULL AND review_state = 'approved') AS songs,
        (SELECT count(*)::int FROM hq_catalog.catalog_providers WHERE retired_at IS NULL) AS providers,
        (SELECT count(*)::int FROM hq_catalog.authorized_media_files WHERE retired_at IS NULL AND review_state = 'approved') AS authorized_media_files,
        (SELECT max(version) FROM hq_catalog.schema_migrations) AS migration_version
    `);
    const counts = rows[0];
    return {
      status: 'ok',
      service: 'hq-catalog',
      framework: 'node:http',
      catalogVersion: 'postgres',
      migrationVersion: counts.migration_version || 'unknown',
      mode: 'postgres',
      counts: {
        songs: counts.songs,
        providers: counts.providers,
        authorizedMediaFiles: counts.authorized_media_files
      }
    };
  }

  async searchSongs(options = {}) {
    const page = positiveInt(options.page, 1);
    const pageSize = pageCap(options.pageSize);
    const offset = (page - 1) * pageSize;
    const values = [];
    const filters = ["s.retired_at IS NULL", "s.review_state = 'approved'"];
    addLike(filters, values, "(s.normalized_artist || ' ' || s.normalized_title)", normalizeCatalogText(options.query));
    addLike(filters, values, 's.normalized_artist', normalizeArtistName(options.artist));
    addLike(filters, values, 's.normalized_title', normalizeCatalogText(options.title));
    const where = filters.join(' AND ');
    const total = (await this.pool.query(`SELECT count(*)::int AS total FROM hq_catalog.songs s WHERE ${where}`, values)).rows[0].total;
    const rows = await this.pool.query(
      `${songSelect()} FROM hq_catalog.songs s WHERE ${where}
       ORDER BY s.normalized_artist, s.normalized_title LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, pageSize, offset]
    );
    return paged(page, pageSize, total, offset, rows.rows.map(toSongSummary));
  }

  async findExactMatch(artistName, title) {
    const artist = normalizeArtistName(artistName);
    const normalizedTitle = normalizeCatalogText(title);
    if (!artist || !normalizedTitle) {
      return null;
    }

    const { rows } = await this.pool.query(
      `${songSelect()} FROM hq_catalog.songs s
       WHERE s.retired_at IS NULL AND s.review_state = 'approved'
         AND s.normalized_artist = $1 AND s.normalized_title = $2
       LIMIT 1`,
      [artist, normalizedTitle]
    );
    return rows[0] ? toSongSummary(rows[0]) : null;
  }

  async getSongDetail(songId) {
    const { rows } = await this.pool.query(
      `${songSelect()} FROM hq_catalog.songs s
       WHERE s.retired_at IS NULL AND s.review_state = 'approved' AND s.song_id = $1
       LIMIT 1`,
      [songId]
    );
    if (!rows[0]) {
      return null;
    }

    return { ...toSongSummary(rows[0]), mediaVersions: await this.getPublicMediaVersions(songId) };
  }

  async listAlternateVersions(songId, options = {}) {
    const page = positiveInt(options.page, 1);
    const pageSize = pageCap(options.pageSize);
    const offset = (page - 1) * pageSize;
    const from = alternateFrom();
    const total = (await this.pool.query(`SELECT count(*)::int AS total ${from}`, [songId])).rows[0].total;
    const { rows } = await this.pool.query(
      `SELECT rel.relationship_id, rel.relationship_type, alt.song_id, alt.title, alt.artist_name,
              alt.normalized_title, alt.normalized_artist, alt.language_code,
              alt.preferred_authorized_media_id, alt.review_state, alt.quality_rating,
              alt.last_verified_at, alt.updated_at
       ${from}
       ORDER BY alt.normalized_artist, alt.normalized_title LIMIT $2 OFFSET $3`,
      [songId, pageSize, offset]
    );
    return paged(page, pageSize, total, offset, rows.map((row) => ({
      relationshipId: row.relationship_id,
      relationshipType: row.relationship_type,
      alternateSong: toSongSummary(row)
    })));
  }

  async createSong(payload, auditContext = {}) {
    return this.withTransaction(async (client) => {
      const songId = payload.songId || randomUUID();
      await client.query(
        `INSERT INTO hq_catalog.songs (
          song_id, title, artist_name, normalized_title, normalized_artist, language_code,
          review_state, quality_rating, authorization_notes, last_verified_at
        ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`,
        [
          songId,
          payload.title,
          payload.artistName,
          normalizeCatalogText(payload.title),
          normalizeArtistName(payload.artistName),
          payload.language || 'und',
          payload.reviewState || 'pending_review',
          payload.qualityRating || null,
          payload.authorizationNotes || null,
          payload.lastVerifiedAt || null
        ]
      );

      const mediaVersions = payload.mediaVersions || [];
      for (const media of mediaVersions) {
        media.authorizedMediaId = media.authorizedMediaId || randomUUID();
        await insertMedia(client, songId, media);
      }

      const preferred = mediaVersions.find((media) => media.isPreferredVersion);
      if (preferred) {
        await client.query('UPDATE hq_catalog.songs SET preferred_authorized_media_id = $1, updated_at = now() WHERE song_id = $2', [
          preferred.authorizedMediaId,
          songId
        ]);
      }

      const after = await getSongSnapshot(client, songId);
      await recordAudit(client, 'song', songId, 'create', null, after, auditContext);
      return toAdminSongFromSnapshot(after);
    });
  }

  async updateSong(songId, payload, auditContext = {}) {
    return this.withTransaction(async (client) => {
      const before = await requireSong(client, songId);
      const updates = [];
      const values = [];
      addUpdate(updates, values, 'title', payload.title);
      if (payload.title !== undefined) addUpdate(updates, values, 'normalized_title', normalizeCatalogText(payload.title));
      addUpdate(updates, values, 'artist_name', payload.artistName);
      if (payload.artistName !== undefined) addUpdate(updates, values, 'normalized_artist', normalizeArtistName(payload.artistName));
      addUpdate(updates, values, 'language_code', payload.language);
      addUpdate(updates, values, 'quality_rating', payload.qualityRating);
      addUpdate(updates, values, 'last_verified_at', payload.lastVerifiedAt);
      updates.push('updated_at = now()');
      values.push(songId);
      await client.query(`UPDATE hq_catalog.songs SET ${updates.join(', ')} WHERE song_id = $${values.length}`, values);
      const after = await getSongSnapshot(client, songId);
      await recordAudit(client, 'song', songId, 'update', before, after, auditContext);
      return toAdminSongFromSnapshot(after);
    });
  }

  async setPreferredVersion(songId, authorizedMediaId, auditContext = {}) {
    return this.withTransaction(async (client) => {
      const before = await requireSong(client, songId);
      const media = await client.query(
        'SELECT 1 FROM hq_catalog.authorized_media_files WHERE song_id = $1 AND authorized_media_id = $2 AND retired_at IS NULL LIMIT 1',
        [songId, authorizedMediaId]
      );
      if (!media.rows[0]) {
        throw new CatalogOperationError('media_not_found', 'Authorized media version was not found for this song.', 404);
      }

      await client.query('UPDATE hq_catalog.authorized_media_files SET is_preferred_version = false, updated_at = now() WHERE song_id = $1', [songId]);
      await client.query(
        'UPDATE hq_catalog.authorized_media_files SET is_preferred_version = true, updated_at = now() WHERE song_id = $1 AND authorized_media_id = $2',
        [songId, authorizedMediaId]
      );
      await client.query('UPDATE hq_catalog.songs SET preferred_authorized_media_id = $2, updated_at = now() WHERE song_id = $1', [
        songId,
        authorizedMediaId
      ]);
      const after = await getSongSnapshot(client, songId);
      await recordAudit(client, 'song', songId, 'set_preferred_version', before, after, auditContext);
      return toAdminSongFromSnapshot(after);
    });
  }

  async setReviewState(songId, reviewState, auditContext = {}) {
    return this.withTransaction(async (client) => {
      const before = await requireSong(client, songId);
      await client.query(
        `UPDATE hq_catalog.songs
         SET review_state = $2,
             retired_at = CASE WHEN $2 = 'retired' THEN COALESCE(retired_at, now()) ELSE retired_at END,
             updated_at = now()
         WHERE song_id = $1`,
        [songId, reviewState]
      );
      const after = await getSongSnapshot(client, songId);
      await recordAudit(client, 'song', songId, 'set_review_state', before, after, auditContext);
      return toAdminSongFromSnapshot(after);
    });
  }

  async updateSourceNotes(songId, authorizationNotes, auditContext = {}) {
    return this.withTransaction(async (client) => {
      const before = await requireSong(client, songId);
      await client.query('UPDATE hq_catalog.songs SET authorization_notes = $2, updated_at = now() WHERE song_id = $1', [
        songId,
        authorizationNotes || null
      ]);
      const after = await getSongSnapshot(client, songId);
      await recordAudit(client, 'song', songId, 'update_source_notes', before, after, auditContext);
      return toAdminSongFromSnapshot(after);
    });
  }

  async retireSong(songId, retirementReason, auditContext = {}) {
    return this.withTransaction(async (client) => {
      const before = await requireSong(client, songId);
      await client.query(
        `UPDATE hq_catalog.songs
         SET review_state = 'retired',
             retired_at = COALESCE(retired_at, now()),
             retirement_reason = $2,
             updated_at = now()
         WHERE song_id = $1`,
        [songId, retirementReason || 'Retired by temporary catalog admin.']
      );
      const after = await getSongSnapshot(client, songId);
      await recordAudit(client, 'song', songId, 'soft_retire', before, after, auditContext);
      return toAdminSongFromSnapshot(after);
    });
  }

  async getAuditHistory(options = {}) {
    const page = positiveInt(options.page, 1);
    const pageSize = pageCap(options.pageSize);
    const offset = (page - 1) * pageSize;
    const values = [];
    const filters = [];
    addEquals(filters, values, 'entity_type', options.entityType);
    addEquals(filters, values, 'entity_id', options.entityId);
    const where = filters.length > 0 ? `WHERE ${filters.join(' AND ')}` : '';
    const total = (await this.pool.query(`SELECT count(*)::int AS total FROM hq_catalog.catalog_change_audit ${where}`, values)).rows[0].total;
    const { rows } = await this.pool.query(
      `SELECT audit_id, entity_type, entity_id, action, actor_label, change_reason,
              before_snapshot, after_snapshot, created_at
       FROM hq_catalog.catalog_change_audit ${where}
       ORDER BY created_at DESC, audit_id DESC LIMIT $${values.length + 1} OFFSET $${values.length + 2}`,
      [...values, pageSize, offset]
    );
    return paged(page, pageSize, total, offset, rows.map(toAuditRecord));
  }

  async getPublicMediaVersions(songId) {
    const { rows } = await this.pool.query(
      `SELECT media.authorized_media_id, media.provider_id, providers.display_name AS provider_name,
              media.provider_track_id, media.file_format, media.vocal_guide_type,
              media.duration_seconds, media.file_size_bytes, media.is_preferred_version,
              media.quality_rating, media.last_verified_at
       FROM hq_catalog.authorized_media_files media
       INNER JOIN hq_catalog.catalog_providers providers ON providers.provider_id = media.provider_id
       WHERE media.retired_at IS NULL AND media.review_state = 'approved' AND media.song_id = $1
       ORDER BY media.is_preferred_version DESC, media.authorized_media_id`,
      [songId]
    );
    return rows.map(toMediaVersion);
  }

  async withTransaction(work) {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const result = await work(client);
      await client.query('COMMIT');
      return result;
    } catch (error) {
      await client.query('ROLLBACK');
      throw normalizePostgresError(error);
    } finally {
      client.release();
    }
  }
}

function alternateFrom() {
  return `
    FROM hq_catalog.alternate_version_relationships rel
    INNER JOIN hq_catalog.songs source
      ON source.song_id = $1 AND source.retired_at IS NULL AND source.review_state = 'approved'
    INNER JOIN hq_catalog.songs alt
      ON alt.song_id = CASE WHEN rel.song_id = $1 THEN rel.alternate_song_id ELSE rel.song_id END
    WHERE rel.retired_at IS NULL AND (rel.song_id = $1 OR rel.alternate_song_id = $1)
      AND alt.retired_at IS NULL AND alt.review_state = 'approved'`;
}

function songSelect() {
  return `SELECT s.song_id, s.title, s.artist_name, s.normalized_title, s.normalized_artist,
                 s.language_code, s.preferred_authorized_media_id, s.review_state,
                 s.quality_rating, s.authorization_notes, s.last_verified_at,
                 s.updated_at, s.retired_at, s.retirement_reason`;
}

function addLike(filters, values, column, value) {
  if (value) {
    values.push(`%${value}%`);
    filters.push(`${column} LIKE $${values.length}`);
  }
}

function addEquals(filters, values, column, value) {
  if (value) {
    values.push(value);
    filters.push(`${column} = $${values.length}`);
  }
}

function addUpdate(updates, values, column, value) {
  if (value !== undefined) {
    values.push(value);
    updates.push(`${column} = $${values.length}`);
  }
}

function pageCap(value) {
  return Math.min(positiveInt(value, DEFAULT_PAGE_SIZE), MAX_PAGE_SIZE);
}

function positiveInt(value, fallback) {
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

function paged(page, pageSize, total, offset, items) {
  return { page, pageSize, total, hasNextPage: offset + pageSize < total, items };
}

async function insertMedia(client, songId, media) {
  await client.query(
    `INSERT INTO hq_catalog.authorized_media_files (
      authorized_media_id, song_id, provider_id, provider_track_id, sha256_checksum,
      file_size_bytes, duration_seconds, file_format, vocal_guide_type,
      storage_relative_key, is_preferred_version, review_state, quality_rating,
      authorization_notes, last_verified_at
    ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)`,
    [
      media.authorizedMediaId,
      songId,
      media.providerId,
      media.providerTrackId || null,
      media.sha256Checksum,
      media.fileSizeBytes,
      media.durationSeconds,
      media.fileFormat,
      media.vocalGuideType || 'unknown',
      media.storageRelativeKey,
      Boolean(media.isPreferredVersion),
      media.reviewState || 'pending_review',
      media.qualityRating || null,
      media.authorizationNotes || null,
      media.lastVerifiedAt || null
    ]
  );
}

async function requireSong(client, songId) {
  const song = await getSongSnapshot(client, songId);
  if (!song) {
    throw new CatalogOperationError('song_not_found', 'Song was not found.', 404);
  }
  return song;
}

async function getSongSnapshot(client, songId) {
  const song = await client.query(`${songSelect()} FROM hq_catalog.songs s WHERE s.song_id = $1 LIMIT 1`, [songId]);
  if (!song.rows[0]) {
    return null;
  }

  const media = await client.query(
    `SELECT authorized_media_id, song_id, provider_id, provider_track_id, file_size_bytes,
            duration_seconds, file_format, vocal_guide_type, storage_relative_key,
            is_preferred_version, review_state, quality_rating, authorization_notes,
            last_verified_at, created_at, updated_at, retired_at, retirement_reason
     FROM hq_catalog.authorized_media_files
     WHERE song_id = $1 ORDER BY authorized_media_id`,
    [songId]
  );
  return { ...toAdminSong(song.rows[0]), mediaVersions: media.rows.map(toAdminMediaVersion) };
}

async function recordAudit(client, entityType, entityId, action, beforeSnapshot, afterSnapshot, auditContext) {
  await client.query(
    `INSERT INTO hq_catalog.catalog_change_audit (
      entity_type, entity_id, action, actor_label, change_reason, before_snapshot, after_snapshot
    ) VALUES ($1, $2, $3, $4, $5, $6::jsonb, $7::jsonb)`,
    [
      entityType,
      entityId,
      action,
      auditContext.actorLabel || 'temporary-admin',
      auditContext.changeReason || null,
      beforeSnapshot ? JSON.stringify(beforeSnapshot) : null,
      afterSnapshot ? JSON.stringify(afterSnapshot) : null
    ]
  );
}

function normalizePostgresError(error) {
  if (error instanceof CatalogOperationError) return error;
  if (error.code === '23503') return new CatalogOperationError('referenced_record_not_found', 'Referenced catalog record was not found.', 400);
  if (error.code === '23505') return new CatalogOperationError('duplicate_catalog_record', 'Catalog record already exists.', 409);
  if (error.code === '23514' || error.code === '22P02') {
    return new CatalogOperationError('invalid_catalog_metadata', 'Catalog metadata did not pass validation.', 400);
  }
  return error;
}

function toIso(value) {
  return value instanceof Date ? value.toISOString() : value;
}

function toSongSummary(row) {
  return {
    songId: row.song_id,
    title: row.title,
    artistName: row.artist_name,
    normalizedTitle: row.normalized_title,
    normalizedArtist: row.normalized_artist,
    language: row.language_code,
    preferredAuthorizedMediaId: row.preferred_authorized_media_id,
    reviewState: row.review_state,
    qualityRating: row.quality_rating,
    lastVerifiedAt: toIso(row.last_verified_at),
    updatedAt: toIso(row.updated_at)
  };
}

function toAdminSong(row) {
  return {
    ...toSongSummary(row),
    authorizationNotes: row.authorization_notes || null,
    retiredAt: toIso(row.retired_at),
    retirementReason: row.retirement_reason || null
  };
}

function toAdminSongFromSnapshot(snapshot) {
  return {
    songId: snapshot.songId,
    title: snapshot.title,
    artistName: snapshot.artistName,
    normalizedTitle: snapshot.normalizedTitle,
    normalizedArtist: snapshot.normalizedArtist,
    language: snapshot.language,
    preferredAuthorizedMediaId: snapshot.preferredAuthorizedMediaId,
    reviewState: snapshot.reviewState,
    qualityRating: snapshot.qualityRating,
    lastVerifiedAt: snapshot.lastVerifiedAt,
    updatedAt: snapshot.updatedAt,
    authorizationNotes: snapshot.authorizationNotes,
    retiredAt: snapshot.retiredAt,
    retirementReason: snapshot.retirementReason
  };
}

function toMediaVersion(row) {
  return {
    authorizedMediaId: row.authorized_media_id,
    providerId: row.provider_id,
    providerName: row.provider_name,
    providerTrackId: row.provider_track_id,
    fileFormat: row.file_format,
    vocalGuideType: row.vocal_guide_type,
    durationSeconds: row.duration_seconds,
    fileSizeBytes: Number(row.file_size_bytes),
    isPreferredVersion: row.is_preferred_version,
    qualityRating: row.quality_rating,
    lastVerifiedAt: toIso(row.last_verified_at)
  };
}

function toAdminMediaVersion(row) {
  return {
    authorizedMediaId: row.authorized_media_id,
    songId: row.song_id,
    providerId: row.provider_id,
    providerTrackId: row.provider_track_id,
    fileSizeBytes: Number(row.file_size_bytes),
    durationSeconds: row.duration_seconds,
    fileFormat: row.file_format,
    vocalGuideType: row.vocal_guide_type,
    storageRelativeKey: row.storage_relative_key,
    isPreferredVersion: row.is_preferred_version,
    reviewState: row.review_state,
    qualityRating: row.quality_rating,
    authorizationNotes: row.authorization_notes,
    lastVerifiedAt: toIso(row.last_verified_at),
    createdAt: toIso(row.created_at),
    updatedAt: toIso(row.updated_at),
    retiredAt: toIso(row.retired_at),
    retirementReason: row.retirement_reason
  };
}

function toAuditRecord(row) {
  return {
    auditId: row.audit_id,
    entityType: row.entity_type,
    entityId: row.entity_id,
    action: row.action,
    actorLabel: row.actor_label,
    changeReason: row.change_reason,
    beforeSnapshot: row.before_snapshot,
    afterSnapshot: row.after_snapshot,
    createdAt: toIso(row.created_at)
  };
}

module.exports = { PostgresCatalogRepository };
