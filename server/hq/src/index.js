const { createCatalogServer } = require('./httpServer');
const { createCatalogRepositoryFromEnvironment } = require('./repositoryFactory');

const port = Number.parseInt(process.env.PORT || '5100', 10);
const repository = createCatalogRepositoryFromEnvironment(process.env);
const server = createCatalogServer({ repository });

server.listen(port, () => {
  console.log(`D & J's HQ catalog API listening on http://localhost:${port}`);
});
