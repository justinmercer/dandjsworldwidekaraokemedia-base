const fs = require('node:fs');
const path = require('node:path');
const { normalizeArtistName, normalizeCatalogText } = require('./normalization');

const DEFAULT_CATALOG_PATH = path.join(__dirname, '..', 'data', 'demo-catalog.json');

function loadDemoCatalog(catalogPath = DEFAULT_CATALOG_PATH) {
  const raw = fs.readFileSync(catalogPath, 'utf8');
  const catalog = JSON.parse(raw);

  for (const song of catalog.songs || []) {
    song.normalizedTitle = song.normalizedTitle || normalizeCatalogText(song.title);
    song.normalizedArtist = song.normalizedArtist || normalizeArtistName(song.artistName);
  }

  return catalog;
}

module.exports = {
  loadDemoCatalog,
  normalizeArtistName,
  normalizeCatalogText
};
