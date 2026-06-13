const { createCatalogServer } = require('./httpServer');
const { loadDemoCatalog } = require('./catalogData');

const port = Number.parseInt(process.env.PORT || '5100', 10);
const server = createCatalogServer({ catalog: loadDemoCatalog() });

server.listen(port, () => {
  console.log(`D & J's HQ catalog API listening on http://localhost:${port}`);
});
