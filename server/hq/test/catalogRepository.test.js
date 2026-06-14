const assert = require('node:assert/strict');
const test = require('node:test');
const { CatalogRepository } = require('../src/catalogRepository');
const { loadDemoCatalog, normalizeArtistName, normalizeCatalogText } = require('../src/catalogData');

test('normalizes searchable artist and title text deterministically', () => {
  assert.equal(normalizeCatalogText(' The DEMO-Artist! '), 'the demo artist');
  assert.equal(normalizeCatalogText('Cafe DUET feat. Guest'), 'cafe duet guest');
  assert.equal(normalizeArtistName('The D.J. Demo & Sample Performer'), 'dj demo sample performer');
  assert.equal(normalizeArtistName('Demo Artist and Guest'), 'demo artist guest');
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

test('alternate-version listing returns public safe alternate songs', () => {
  const repository = new CatalogRepository(loadDemoCatalog());
  const result = repository.listAlternateVersions('song_demo_opening');

  assert.equal(result.total, 1);
  assert.equal(result.items[0].relationshipId, 'alternate_demo_opening_duet');
  assert.equal(result.items[0].alternateSong.songId, 'song_demo_duet');
  assert.equal(JSON.stringify(result).includes('notes'), false);
});

test('catalog writes produce protected audit history records', () => {
  const repository = new CatalogRepository(loadDemoCatalog());
  const song = repository.createSong({
    songId: 'song_demo_admin_created',
    title: 'Cafe Demo & Guest',
    artistName: 'The D.J. Demo feat. Guest',
    language: 'en',
    reviewState: 'pending_review',
    authorizationNotes: 'Synthetic admin-created metadata only.'
  }, {
    actorLabel: 'test-admin',
    changeReason: 'node test'
  });

  assert.equal(song.normalizedTitle, 'cafe demo guest');
  assert.equal(song.normalizedArtist, 'dj demo guest');

  const updated = repository.updateSong(song.songId, { title: 'Cafe Demo Final' }, { actorLabel: 'test-admin' });
  assert.equal(updated.normalizedTitle, 'cafe demo final');

  const reviewed = repository.setReviewState(song.songId, 'approved', { actorLabel: 'test-admin' });
  assert.equal(reviewed.reviewState, 'approved');

  const noted = repository.updateSourceNotes(song.songId, 'Synthetic note update.', { actorLabel: 'test-admin' });
  assert.equal(noted.authorizationNotes, 'Synthetic note update.');

  const retired = repository.retireSong(song.songId, 'Synthetic retirement.', { actorLabel: 'test-admin' });
  assert.equal(retired.reviewState, 'retired');
  assert.equal(retired.retirementReason, 'Synthetic retirement.');

  const audit = repository.getAuditHistory({ entityType: 'song', entityId: song.songId, pageSize: 10 });
  assert.equal(audit.total, 5);
  assert.equal(audit.items.every((item) => item.actorLabel === 'test-admin'), true);
});
