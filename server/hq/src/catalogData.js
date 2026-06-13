const fs = require('node:fs');
const path = require('node:path');

const DEFAULT_CATALOG_PATH = path.join(__dirname, '..', 'data', 'demo-catalog.json');

function normalizeCatalogText(value) {
  return String(value || '')
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

function loadDemoCatalog(catalogPath = DEFAULT_CATALOG_PATH) {
  const raw = fs.readFileSync(catalogPath, 'utf8');
  const catalog = JSON.parse(raw);

  for (const song of catalog.songs || []) {
    song.normalizedTitle = song.normalizedTitle || normalizeCatalogText(song.title);
    song.normalizedArtist = song.normalizedArtist || normalizeCatalogText(song.artistName);
  }

  return catalog;
}

module.exports = {
  loadDemoCatalog,
  normalizeCatalogText
};
