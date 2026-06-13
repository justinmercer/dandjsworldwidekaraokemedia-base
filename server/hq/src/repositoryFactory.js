const { CatalogRepository } = require('./catalogRepository');
const { loadDemoCatalog } = require('./catalogData');
const { PostgresCatalogRepository } = require('./postgresCatalogRepository');

function createCatalogRepositoryFromEnvironment(env = process.env) {
  if (env.DATABASE_URL) {
    return new PostgresCatalogRepository({ databaseUrl: env.DATABASE_URL });
  }

  if (env.HQ_CATALOG_MODE === 'demo' || env.DEMO_MODE === 'true') {
    return new CatalogRepository(loadDemoCatalog());
  }

  throw new Error('Set DATABASE_URL for PostgreSQL mode or DEMO_MODE=true for explicit demo catalog mode.');
}

module.exports = {
  createCatalogRepositoryFromEnvironment
};
