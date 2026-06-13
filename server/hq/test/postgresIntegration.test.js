const assert = require('node:assert/strict');
const test = require('node:test');
const { PostgresCatalogRepository } = require('../src/postgresCatalogRepository');
const { createCatalogServer } = require('../src/httpServer');

const databaseUrl = process.env.DATABASE_URL;

test('PostgreSQL catalog counts and read-only endpoints work', { skip: !databaseUrl }, async () => {
  const repository = new PostgresCatalogRepository({ databaseUrl });
  const server = createCatalogServer({ repository });

  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const { port } = server.address();
  const baseUrl = `http://127.0.0.1:${port}`;

  try {
    const health = await fetch(`${baseUrl}/healthz`);
    const healthBody = await health.json();
    assert.equal(health.status, 200);
    assert.equal(healthBody.mode, 'postgres');
    assert.deepEqual(healthBody.counts, {
      songs: 3,
      providers: 2,
      authorizedMediaFiles: 4
    });

    const search = await fetch(`${baseUrl}/api/catalog/search?query=demo&page=1&pageSize=10`);
    const searchBody = await search.json();
    assert.equal(search.status, 200);
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

    const writeAttempt = await fetch(`${baseUrl}/api/catalog/search`, { method: 'POST' });
    const writeBody = await writeAttempt.json();
    assert.equal(writeAttempt.status, 405);
    assert.equal(writeBody.error.code, 'read_only_endpoint');
  } finally {
    await new Promise((resolve) => server.close(resolve));
    await repository.close();
  }
});
