const assert = require('node:assert/strict');
const test = require('node:test');
const { CatalogRepository } = require('../src/catalogRepository');
const { createCatalogRepositoryFromEnvironment } = require('../src/repositoryFactory');

test('uses explicit demo mode only when no database URL is configured', () => {
  const repository = createCatalogRepositoryFromEnvironment({ DEMO_MODE: 'true' });
  assert.equal(repository instanceof CatalogRepository, true);
});

test('fails fast instead of silently falling back to JSON catalog', () => {
  assert.throws(
    () => createCatalogRepositoryFromEnvironment({}),
    /Set DATABASE_URL/
  );
});
