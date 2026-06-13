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
    const result = await this.pool.query(`
      SELECT
        (SELECT count(*)::int FROM hq_catalog.songs WHERE retired_at IS NULL AND review_state = 'approved') AS songs,
        (SELECT count(*)::int FROM hq_catalog.catalog_providers WHERE retired_at IS NULL) AS providers,
        (SELECT count(*)::int FROM hq_catalog.authorized_media_files WHERE retired_at IS NULL AND review_state = 'approved') AS authorized_media_files
    `);
    const counts = result.rows[0];

    return {
      status: 'ok',
      service: 'hq-catalog',
      framework: 'node:http',
      catalogVersion: 'postgres',
      migrationVersion: '0001_authorized_catalog',
      mode: 'postgres',
      counts: {
        songs: counts.songs,
        providers: counts.providers,
        authorizedMediaFiles: counts.authorized_media_files
      }
    };
  }

  async searchSongs(options = {}) {
    const page = toPositiveInteger(options.page, 1);
    const pageSize = Math.min(toPositiveInteger(options.pageSize, DEFAULT_PAGE_SIZE), MAX_PAGE_SIZE);
    const offset = (page - 1) * pageSize;
    const query = normalizeCatalogText(options.query);
    const artist = normalizeCatalogText(options.artist);
    const title = normalizeCatalogText(options.title);
    const values = [];
    const filters = [
      "s.retired_at IS NULL",
      "s.review_state = 'approved'"
    ];

    if (query) {
      values.push(`%${query}%`);
      filters.push(`(s.normalized_artist || ' ' || s.normalized_title) LIKE $${values.length}`);
    }
    if (artist) {
      values.push(`%${artist}%`);
      filters.push(`s.normalized_artist LIKE $${values.length}`);
    }
    if (title) {
      values.push(`%${title}%`);
      filters.push(`s.normalized_title LIKE $${values.length}`);
    }

    const whereClause = filters.join(' AND ');
    const countResult = await this.pool.query(
      `SELECT count(*)::int AS total FROM hq_catalog.songs s WHERE ${whereClause}`,
      values
    );

    values.push(pageSize);
    const limitParam = values.length;
    values.push(offset);
    const offsetParam = values.length;

    const rows = await this.pool.query(
      `
      SELECT
        s.song_id,
        s.title,
        s.artist_name,
        s.normalized_title,
        s.normalized_artist,
        s.language_code,
        s.preferred_authorized_media_id,
        s.review_state,
        s.quality_rating,
        s.last_verified_at,
        s.updated_at
      FROM hq_catalog.songs s
      WHERE ${whereClause}
      ORDER BY s.normalized_artist, s.normalized_title
      LIMIT $${limitParam} OFFSET $${offsetParam}
      `,
      values
    );

    const total = countResult.rows[0].total;
    return {
      page,
      pageSize,
      total,
      hasNextPage: offset + pageSize < total,
      items: rows.rows.map(toSongSummary)
    };
  }

  async findExactMatch(artistName, title) {
    const normalizedArtist = normalizeCatalogText(artistName);
    const normalizedTitle = normalizeCatalogText(title);

    if (!normalizedArtist || !normalizedTitle) {
      return null;
    }

    const result = await this.pool.query(
      `
      SELECT
        s.song_id,
        s.title,
        s.artist_name,
        s.normalized_title,
        s.normalized_artist,
        s.language_code,
        s.preferred_authorized_media_id,
        s.review_state,
        s.quality_rating,
        s.last_verified_at,
        s.updated_at
      FROM hq_catalog.songs s
      WHERE s.retired_at IS NULL
        AND s.review_state = 'approved'
        AND s.normalized_artist = $1
        AND s.normalized_title = $2
      LIMIT 1
      `,
      [normalizedArtist, normalizedTitle]
    );

    return result.rows[0] ? toSongSummary(result.rows[0]) : null;
  }

  async getSongDetail(songId) {
    const songResult = await this.pool.query(
      `
      SELECT
        s.song_id,
        s.title,
        s.artist_name,
        s.normalized_title,
        s.normalized_artist,
        s.language_code,
        s.preferred_authorized_media_id,
        s.review_state,
        s.quality_rating,
        s.last_verified_at,
        s.updated_at
      FROM hq_catalog.songs s
      WHERE s.retired_at IS NULL
        AND s.review_state = 'approved'
        AND s.song_id = $1
      LIMIT 1
      `,
      [songId]
    );

    if (!songResult.rows[0]) {
      return null;
    }

    const mediaResult = await this.pool.query(
      `
      SELECT
        media.authorized_media_id,
        media.provider_id,
        providers.display_name AS provider_name,
        media.provider_track_id,
        media.file_format,
        media.vocal_guide_type,
        media.duration_seconds,
        media.file_size_bytes,
        media.is_preferred_version,
        media.quality_rating,
        media.last_verified_at
      FROM hq_catalog.authorized_media_files media
      INNER JOIN hq_catalog.catalog_providers providers
        ON providers.provider_id = media.provider_id
      WHERE media.retired_at IS NULL
        AND media.review_state = 'approved'
        AND media.song_id = $1
      ORDER BY media.is_preferred_version DESC, media.authorized_media_id
      `,
      [songId]
    );

    return {
      ...toSongSummary(songResult.rows[0]),
      mediaVersions: mediaResult.rows.map(toMediaVersion)
    };
  }
}

function normalizeCatalogText(value) {
  return String(value || '')
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

function toPositiveInteger(value, fallback) {
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed) || parsed < 1) {
    return fallback;
  }

  return parsed;
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

function toMediaVersion(row) {
  return {
    authorizedMediaId: row.authorized_media_id,
    providerId: row.provider_id,
    providerName: row.provider_name,
    providerTrackId: row.provider_track_id,
    fileFormat: row.file_format,
    vocalGuideType: row.vocal_guide_type,
    durationSeconds: row.duration_seconds,
    fileSizeBytes: row.file_size_bytes,
    isPreferredVersion: row.is_preferred_version,
    qualityRating: row.quality_rating,
    lastVerifiedAt: toIso(row.last_verified_at)
  };
}

module.exports = {
  PostgresCatalogRepository
};
