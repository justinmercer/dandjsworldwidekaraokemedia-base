const assert = require('node:assert/strict');
const test = require('node:test');
const { createCatalogServer } = require('../src/httpServer');
const { CatalogRepository } = require('../src/catalogRepository');
const { loadDemoCatalog } = require('../src/catalogData');

async function withServer(run) {
  const server = createCatalogServer({ repository: new CatalogRepository(loadDemoCatalog()) });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const { port } = server.address();

  try {
    await run(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

test('health endpoint reports the runnable catalog foundation', async () => {
  await withServer(async (baseUrl) => {
    const response = await fetch(`${baseUrl}/healthz`);
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.equal(body.status, 'ok');
    assert.equal(body.service, 'hq-catalog');
    assert.equal(body.framework, 'node:http');
  });
});

test('search, exact match, and detail endpoints are read-only catalog endpoints', async () => {
  await withServer(async (baseUrl) => {
    const search = await fetch(`${baseUrl}/api/catalog/search?query=opening&page=1&pageSize=5`);
    const searchBody = await search.json();
    assert.equal(search.status, 200);
    assert.equal(searchBody.total, 1);
    assert.equal(searchBody.items[0].songId, 'song_demo_opening');

    const exact = await fetch(`${baseUrl}/api/catalog/exact-match?artist=Demo%20Artist&title=Demo%20Opening%20Song`);
    const exactBody = await exact.json();
    assert.equal(exact.status, 200);
    assert.equal(exactBody.match.songId, 'song_demo_opening');

    const detail = await fetch(`${baseUrl}/api/catalog/songs/song_demo_opening`);
    const detailBody = await detail.json();
    assert.equal(detail.status, 200);
    assert.equal(detailBody.song.mediaVersions.length, 2);

    const writeAttempt = await fetch(`${baseUrl}/api/catalog/search`, { method: 'POST' });
    const writeBody = await writeAttempt.json();
    assert.equal(writeAttempt.status, 405);
    assert.equal(writeBody.error.code, 'read_only_endpoint');
  });
});

test('alternate-version listing route stays out of this batch', async () => {
  await withServer(async (baseUrl) => {
    const response = await fetch(`${baseUrl}/api/catalog/songs/song_demo_opening/alternate-versions`);
    assert.equal(response.status, 404);
  });
});
