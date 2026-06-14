const { createCatalogServer } = require('./httpServer');
const { createCatalogRepositoryFromEnvironment } = require('./repositoryFactory');

const port = Number.parseInt(process.env.PORT || '5100', 10);
const repository = createCatalogRepositoryFromEnvironment(process.env);
const server = createCatalogServer({
  adminCredential: process.env.HQ_ADMIN_TOKEN,
  hostRegistrationCredential: process.env.HQ_HOST_REGISTRATION_TOKEN,
  repository
});

server.listen(port, () => {
  console.log(`D & J's HQ catalog API listening on http://localhost:${port}`);
});
