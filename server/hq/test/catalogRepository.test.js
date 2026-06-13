const assert = require('node:assert/strict');
const test = require('node:test');
const { CatalogRepository } = require('../src/catalogRepository');
const { loadDemoCatalog, normalizeCatalogText } = require('../src/catalogData');

test('normalizes searchable artist and title text', () => {
  assert.equal(normalizeCatalogText(' The DEMO-Artist! '), 'the demo artist');
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
