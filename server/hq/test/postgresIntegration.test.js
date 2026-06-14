const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const test = require('node:test');
const { PostgresCatalogRepository } = require('../src/postgresCatalogRepository');
const { createCatalogServer } = require('../src/httpServer');

const databaseUrl = process.env.DATABASE_URL;
const ADMIN_TOKEN = 'placeholder-test-admin-token';

function adminHeaders(extra = {}) {
  return {
    authorization: `Bearer ${ADMIN_TOKEN}`,
    'content-type': 'application/json',
    'x-admin-actor': 'postgres-test-admin',
    ...extra
  };
}

test('PostgreSQL catalog reads, protected writes, audit history, and normalization work', { skip: !databaseUrl }, async () => {
  const repository = new PostgresCatalogRepository({ databaseUrl });
  const createdSongId = randomUUID();
  const server = createCatalogServer({
    adminCredential: ADMIN_TOKEN,
    repository
  });

  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const { port } = server.address();
  const baseUrl = `http://127.0.0.1:${port}`;

  try {
    const health = await fetch(`${baseUrl}/healthz`);
    const healthBody = await health.json();
    assert.equal(health.status, 200);
    assert.equal(healthBody.mode, 'postgres');
    assert.equal(healthBody.migrationVersion, '0002');
    assert.deepEqual(healthBody.counts, {
      songs: 3,
      providers: 2,
      authorizedMediaFiles: 4
    });

    const search = await fetch(`${baseUrl}/api/catalog/search?query=demo&page=1&pageSize=1000`);
    const searchBody = await search.json();
    assert.equal(search.status, 200);
    assert.equal(searchBody.pageSize, 50);
    assert.equal(searchBody.total, 3);
    assert.equal(searchBody.items.some((item) => item.songId === '00000000-0000-4000-8000-000000000201'), true);

    const exact = await fetch(`${baseUrl}/api/catalog/exact-match?artist=Demo%20Artist&title=Demo%20Opening%20Song`);
    const exactBody = await exact.json();
    assert.equal(exact.status, 200);
    assert.equal(exactBody.match.songId, '00000000-0000-4000-8000-000000000201');

    const detail = await fetch(`${baseUrl}/api/catalog/songs/00000000-0000-4000-8000-000000000201`);
    const detailBody = await detail.json();
    assert.equal(detail.status, 200);
    assert.equal(detailBody.song.mediaVersions.length, 2);

    const serialized = JSON.stringify(detailBody);
    assert.equal(serialized.includes('storageRelativeKey'), false);
    assert.equal(serialized.includes('sha256Checksum'), false);
    assert.equal(serialized.includes('demo-catalog/opening'), false);

    const alternate = await fetch(`${baseUrl}/api/catalog/songs/00000000-0000-4000-8000-000000000201/alternate-versions`);
    const alternateBody = await alternate.json();
    assert.equal(alternate.status, 200);
    assert.equal(alternateBody.total, 1);
    assert.equal(alternateBody.items[0].alternateSong.songId, '00000000-0000-4000-8000-000000000203');

    const writeAttempt = await fetch(`${baseUrl}/api/catalog/search`, { method: 'POST' });
    const writeBody = await writeAttempt.json();
    assert.equal(writeAttempt.status, 405);
    assert.equal(writeBody.error.code, 'read_only_endpoint');

    const protectedWithoutToken = await fetch(`${baseUrl}/api/admin/catalog/audit`);
    const protectedBody = await protectedWithoutToken.json();
    assert.equal(protectedWithoutToken.status, 401);
    assert.equal(protectedBody.error.code, 'admin_unauthorized');

    const preferred = await fetch(`${baseUrl}/api/admin/catalog/songs/00000000-0000-4000-8000-000000000201/preferred-version`, {
      method: 'PUT',
      headers: adminHeaders(),
      body: JSON.stringify({ authorizedMediaId: '00000000-0000-4000-8000-000000000302' })
    });
    const preferredBody = await preferred.json();
    assert.equal(preferred.status, 200);
    assert.equal(preferredBody.song.preferredAuthorizedMediaId, '00000000-0000-4000-8000-000000000302');

    const create = await fetch(`${baseUrl}/api/admin/catalog/songs`, {
      method: 'POST',
      headers: adminHeaders(),
      body: JSON.stringify({
        songId: createdSongId,
        title: 'Cafe Demo & Guest',
        artistName: 'The D.J. Demo feat. Guest',
        language: 'en',
        reviewState: 'pending_review',
        authorizationNotes: 'Synthetic PostgreSQL admin-created metadata only.'
      })
    });
    const created = await create.json();
    assert.equal(create.status, 201);
    assert.equal(created.song.normalizedTitle, 'cafe demo guest');
    assert.equal(created.song.normalizedArtist, 'dj demo guest');

    const update = await fetch(`${baseUrl}/api/admin/catalog/songs/${created.song.songId}`, {
      method: 'PATCH',
      headers: adminHeaders(),
      body: JSON.stringify({ title: 'Cafe Demo Final' })
    });
    assert.equal(update.status, 200);

    const review = await fetch(`${baseUrl}/api/admin/catalog/songs/${created.song.songId}/review-state`, {
      method: 'PATCH',
      headers: adminHeaders(),
      body: JSON.stringify({ reviewState: 'approved' })
    });
    assert.equal(review.status, 200);

    const normalizedSearch = await fetch(`${baseUrl}/api/catalog/search?artist=DJ%20Demo%20and%20Guest&title=Caf%C3%A9%20Demo%20Final`);
    const normalizedBody = await normalizedSearch.json();
    assert.equal(normalizedSearch.status, 200);
    assert.equal(normalizedBody.total, 1);
    assert.equal(normalizedBody.items[0].songId, created.song.songId);

    const notes = await fetch(`${baseUrl}/api/admin/catalog/songs/${created.song.songId}/source-notes`, {
      method: 'PATCH',
      headers: adminHeaders(),
      body: JSON.stringify({ authorizationNotes: 'Synthetic PostgreSQL source note update.' })
    });
    assert.equal(notes.status, 200);

    const retire = await fetch(`${baseUrl}/api/admin/catalog/songs/${created.song.songId}/retire`, {
      method: 'POST',
      headers: adminHeaders(),
      body: JSON.stringify({ retirementReason: 'Synthetic PostgreSQL retirement.' })
    });
    const retired = await retire.json();
    assert.equal(retire.status, 200);
    assert.equal(retired.song.reviewState, 'retired');

    const afterRetire = await fetch(`${baseUrl}/api/catalog/search?artist=DJ%20Demo%20Guest&title=Cafe%20Demo%20Final`);
    const afterRetireBody = await afterRetire.json();
    assert.equal(afterRetire.status, 200);
    assert.equal(afterRetireBody.total, 0);

    const audit = await fetch(`${baseUrl}/api/admin/catalog/audit?entityType=song&entityId=${created.song.songId}`, {
      headers: adminHeaders()
    });
    const auditBody = await audit.json();
    assert.equal(audit.status, 200);
    assert.equal(auditBody.total, 5);
    assert.equal(auditBody.items.every((item) => item.actorLabel === 'postgres-test-admin'), true);

    const malformed = await fetch(`${baseUrl}/api/admin/catalog/songs`, {
      method: 'POST',
      headers: adminHeaders(),
      body: JSON.stringify({ title: 'Missing artist' })
    });
    const malformedBody = await malformed.json();
    assert.equal(malformed.status, 400);
    assert.equal(malformedBody.error.code, 'validation_failed');
  } finally {
    await new Promise((resolve) => server.close(resolve));
    await repository.close();
  }
});
