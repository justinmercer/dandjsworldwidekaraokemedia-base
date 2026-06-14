const assert = require('node:assert/strict');
const test = require('node:test');
const { createCatalogServer } = require('../src/httpServer');
const { CatalogRepository } = require('../src/catalogRepository');
const { loadDemoCatalog } = require('../src/catalogData');

const ADMIN_TOKEN = 'placeholder-test-admin-token';
const HOST_TOKEN = 'placeholder-test-host-registration-token';

async function withServer(options, run) {
  const server = createCatalogServer({
    repository: new CatalogRepository(loadDemoCatalog()),
    ...options
  });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const { port } = server.address();

  try {
    await run(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

function adminHeaders(extra = {}) {
  return {
    authorization: `Bearer ${ADMIN_TOKEN}`,
    'content-type': 'application/json',
    'x-admin-actor': 'test-admin',
    ...extra
  };
}

function hostHeaders(extra = {}) {
  return {
    authorization: `Bearer ${HOST_TOKEN}`,
    'content-type': 'application/json',
    ...extra
  };
}

test('health endpoint reports the runnable catalog foundation', async () => {
  await withServer({}, async (baseUrl) => {
    const response = await fetch(`${baseUrl}/healthz`);
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.equal(body.status, 'ok');
    assert.equal(body.service, 'hq-catalog');
    assert.equal(body.framework, 'node:http');
  });
});

test('public read endpoints stay filtered and read-only', async () => {
  await withServer({}, async (baseUrl) => {
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
    assert.equal(JSON.stringify(detailBody).includes('storageRelativeKey'), false);

    const alternate = await fetch(`${baseUrl}/api/catalog/songs/song_demo_opening/alternate-versions`);
    const alternateBody = await alternate.json();
    assert.equal(alternate.status, 200);
    assert.equal(alternateBody.total, 1);
    assert.equal(alternateBody.items[0].alternateSong.songId, 'song_demo_duet');

    const writeAttempt = await fetch(`${baseUrl}/api/catalog/search`, { method: 'POST' });
    const writeBody = await writeAttempt.json();
    assert.equal(writeAttempt.status, 405);
    assert.equal(writeBody.error.code, 'read_only_endpoint');
  });
});

test('admin routes fail closed when no temporary credential is configured', async () => {
  await withServer({}, async (baseUrl) => {
    const response = await fetch(`${baseUrl}/api/admin/catalog/audit`);
    const body = await response.json();

    assert.equal(response.status, 503);
    assert.equal(body.error.code, 'admin_auth_not_configured');
  });
});

test('admin routes require the configured temporary credential', async () => {
  await withServer({ adminCredential: ADMIN_TOKEN }, async (baseUrl) => {
    const response = await fetch(`${baseUrl}/api/admin/catalog/audit`);
    const body = await response.json();

    assert.equal(response.status, 401);
    assert.equal(body.error.code, 'admin_unauthorized');
  });
});

test('host routes fail closed without registration configuration and reject bad tokens', async () => {
  await withServer({}, async (baseUrl) => {
    const missingConfig = await fetch(`${baseUrl}/api/host/register`, {
      method: 'POST',
      headers: hostHeaders(),
      body: JSON.stringify({ displayName: 'Demo Host' })
    });
    const missingBody = await missingConfig.json();
    assert.equal(missingConfig.status, 503);
    assert.equal(missingBody.error.code, 'host_registration_not_configured');
  });

  await withServer({ hostRegistrationCredential: HOST_TOKEN }, async (baseUrl) => {
    const invalid = await fetch(`${baseUrl}/api/host/register`, {
      method: 'POST',
      headers: { authorization: 'Bearer wrong-placeholder-token', 'content-type': 'application/json' },
      body: JSON.stringify({ displayName: 'Demo Host' })
    });
    const invalidBody = await invalid.json();
    assert.equal(invalid.status, 401);
    assert.equal(invalidBody.error.code, 'host_unauthorized');
  });
});

test('host registration heartbeat admin status manifest and diff endpoints are protected and safe', async () => {
  await withServer({
    adminCredential: ADMIN_TOKEN,
    hostRegistrationCredential: HOST_TOKEN
  }, async (baseUrl) => {
    const register = await fetch(`${baseUrl}/api/host/register`, {
      method: 'POST',
      headers: hostHeaders(),
      body: JSON.stringify({
        hostDeviceId: 'host_demo_main',
        displayName: 'Demo Booth Laptop',
        venueLabel: 'Demo Venue',
        appVersion: '0.2.0-demo',
        localFreeSpaceBytes: 987654321,
        localLibraryRoot: 'C:\\Demo\\Karaoke'
      })
    });
    const registered = await register.json();
    assert.equal(register.status, 201);
    assert.equal(registered.hostDevice.hostDeviceId, 'host_demo_main');
    assert.equal(registered.hostDevice.localLibraryRootReported, true);
    assert.equal(JSON.stringify(registered).includes('C:\\Demo\\Karaoke'), false);

    const heartbeat = await fetch(`${baseUrl}/api/host/heartbeat`, {
      method: 'POST',
      headers: hostHeaders(),
      body: JSON.stringify({
        hostDeviceId: 'host_demo_main',
        appVersion: '0.2.1-demo',
        localFreeSpaceBytes: 987650000,
        isActive: true,
        syncState: 'interrupted',
        interruptedSyncState: {
          syncId: 'sync-demo-001',
          reason: 'Synthetic interrupted sync marker.',
          lastMediaKey: 'authorized-media:media_demo_opening_cdg',
          interruptedAt: '2026-06-14T00:00:00Z'
        }
      })
    });
    const heartbeatBody = await heartbeat.json();
    assert.equal(heartbeat.status, 200);
    assert.equal(heartbeatBody.hostDevice.syncState, 'interrupted');

    const statuses = await fetch(`${baseUrl}/api/admin/hosts/status`, {
      headers: adminHeaders()
    });
    const statusBody = await statuses.json();
    assert.equal(statuses.status, 200);
    assert.equal(statusBody.total, 1);
    assert.equal(statusBody.items[0].localLibraryRootReported, true);

    const manifest = await fetch(`${baseUrl}/api/host/manifest?hostDeviceId=host_demo_main`, {
      headers: hostHeaders()
    });
    const manifestBody = await manifest.json();
    const serializedManifest = JSON.stringify(manifestBody);
    assert.equal(manifest.status, 200);
    assert.equal(manifestBody.entries.length, 3);
    assert.equal(manifestBody.entries[0].authorizedMediaId, 'media_demo_opening_cdg');
    assert.equal(manifestBody.entries.some((entry) => entry.authorizedMediaId === 'media_demo_opening_guide'), false);
    assert.equal(serializedManifest.includes('storageRelativeKey'), false);
    assert.equal(serializedManifest.includes('demo-catalog'), false);
    assert.match(manifestBody.manifestVersion, /^[0-9a-f]{64}$/);

    const diff = await fetch(`${baseUrl}/api/host/manifest/diff`, {
      method: 'POST',
      headers: hostHeaders(),
      body: JSON.stringify({
        hostDeviceId: 'host_demo_main',
        currentEntries: [
          {
            songId: 'song_demo_opening',
            authorizedMediaId: 'media_demo_opening_cdg',
            sha256Checksum: '0000000000000000000000000000000000000000000000000000000000000000',
            fileSizeBytes: 1,
            versionTimestamp: '2026-01-01T00:00:00Z'
          },
          {
            songId: 'song_demo_stale',
            authorizedMediaId: 'media_demo_stale',
            sha256Checksum: '5555555555555555555555555555555555555555555555555555555555555555',
            fileSizeBytes: 10,
            versionTimestamp: '2026-01-01T00:00:00Z'
          }
        ]
      })
    });
    const diffBody = await diff.json();
    assert.equal(diff.status, 200);
    assert.equal(diffBody.totals.additions, 2);
    assert.equal(diffBody.totals.updates, 1);
    assert.equal(diffBody.cleanupCandidates[0].deleteReady, false);
  });
});

test('protected catalog-management endpoints create audit history', async () => {
  await withServer({ adminCredential: ADMIN_TOKEN }, async (baseUrl) => {
    const create = await fetch(`${baseUrl}/api/admin/catalog/songs`, {
      method: 'POST',
      headers: adminHeaders(),
      body: JSON.stringify({
        songId: 'song_http_admin_created',
        title: 'Cafe Demo & Guest',
        artistName: 'The D.J. Demo feat. Guest',
        language: 'en',
        reviewState: 'pending_review',
        authorizationNotes: 'Synthetic admin-created metadata only.'
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

    const notes = await fetch(`${baseUrl}/api/admin/catalog/songs/${created.song.songId}/source-notes`, {
      method: 'PATCH',
      headers: adminHeaders(),
      body: JSON.stringify({ authorizationNotes: 'Synthetic source note update.' })
    });
    assert.equal(notes.status, 200);

    const retire = await fetch(`${baseUrl}/api/admin/catalog/songs/${created.song.songId}/retire`, {
      method: 'POST',
      headers: adminHeaders(),
      body: JSON.stringify({ retirementReason: 'Synthetic retirement.' })
    });
    const retired = await retire.json();
    assert.equal(retire.status, 200);
    assert.equal(retired.song.reviewState, 'retired');

    const audit = await fetch(`${baseUrl}/api/admin/catalog/audit?entityType=song&entityId=${created.song.songId}`, {
      headers: adminHeaders()
    });
    const auditBody = await audit.json();
    assert.equal(audit.status, 200);
    assert.equal(auditBody.total, 5);
    assert.equal(auditBody.items.every((item) => item.actorLabel === 'test-admin'), true);
  });
});

test('preferred-version endpoint updates an existing media selection', async () => {
  await withServer({ adminCredential: ADMIN_TOKEN }, async (baseUrl) => {
    const response = await fetch(`${baseUrl}/api/admin/catalog/songs/song_demo_opening/preferred-version`, {
      method: 'PUT',
      headers: adminHeaders(),
      body: JSON.stringify({ authorizedMediaId: 'media_demo_opening_guide' })
    });
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.equal(body.song.preferredAuthorizedMediaId, 'media_demo_opening_guide');
  });
});

test('malformed metadata returns user-safe validation errors', async () => {
  await withServer({ adminCredential: ADMIN_TOKEN }, async (baseUrl) => {
    const response = await fetch(`${baseUrl}/api/admin/catalog/songs`, {
      method: 'POST',
      headers: adminHeaders(),
      body: JSON.stringify({ title: 'Missing artist' })
    });
    const body = await response.json();

    assert.equal(response.status, 400);
    assert.equal(body.error.code, 'validation_failed');
    assert.equal(body.error.message.includes('artistName'), true);
  });
});

test('public search is rate limited', async () => {
  await withServer({ publicSearchRateLimit: { max: 1, windowMs: 60_000 } }, async (baseUrl) => {
    const first = await fetch(`${baseUrl}/api/catalog/search?query=demo`, {
      headers: { 'x-forwarded-for': '198.51.100.10' }
    });
    assert.equal(first.status, 200);

    const second = await fetch(`${baseUrl}/api/catalog/search?query=demo`, {
      headers: { 'x-forwarded-for': '198.51.100.10' }
    });
    const body = await second.json();
    assert.equal(second.status, 429);
    assert.equal(body.error.code, 'rate_limited');
  });
});
