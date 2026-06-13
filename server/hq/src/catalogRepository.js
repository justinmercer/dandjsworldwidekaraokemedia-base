const { normalizeCatalogText } = require('./catalogData');

const DEFAULT_PAGE_SIZE = 20;
const MAX_PAGE_SIZE = 50;

class CatalogRepository {
  constructor(catalog) {
    this.catalog = catalog;
    this.providersById = new Map((catalog.providers || []).map((provider) => [provider.providerId, provider]));
    this.songsById = new Map((catalog.songs || []).map((song) => [song.songId, song]));
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
    const artist = normalizeCatalogText(options.artist);
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
    const normalizedArtist = normalizeCatalogText(artistName);
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

module.exports = {
  CatalogRepository
};
