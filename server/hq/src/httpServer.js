const http = require('node:http');
const { randomUUID } = require('node:crypto');
const { CatalogRepository } = require('./catalogRepository');
const { loadDemoCatalog } = require('./catalogData');

function createCatalogServer(options = {}) {
  const repository = options.repository || new CatalogRepository(options.catalog || loadDemoCatalog());

  return http.createServer((request, response) => {
    const correlationId = request.headers['x-correlation-id'] || randomUUID();
    response.setHeader('x-correlation-id', correlationId);

    try {
      routeRequest(request, response, repository);
    } catch (error) {
      writeJson(response, 500, {
        error: {
          code: 'internal_error',
          message: 'Catalog request failed.'
        }
      });
    }
  });
}

function routeRequest(request, response, repository) {
  const requestUrl = new URL(request.url, 'http://localhost');
  const pathname = requestUrl.pathname.replace(/\/+$/, '') || '/';

  if (request.method !== 'GET' && isCatalogPath(pathname)) {
    writeJson(response, 405, {
      error: {
        code: 'read_only_endpoint',
        message: 'Catalog endpoints are read-only in this batch.'
      }
    });
    return;
  }

  if (request.method === 'GET' && (pathname === '/healthz' || pathname === '/api/catalog/healthz')) {
    writeJson(response, 200, repository.getHealth());
    return;
  }

  if (request.method === 'GET' && pathname === '/api/catalog/search') {
    writeJson(response, 200, repository.searchSongs(Object.fromEntries(requestUrl.searchParams.entries())));
    return;
  }

  if (request.method === 'GET' && pathname === '/api/catalog/exact-match') {
    const match = repository.findExactMatch(
      requestUrl.searchParams.get('artistName') || requestUrl.searchParams.get('artist'),
      requestUrl.searchParams.get('title')
    );

    writeJson(response, 200, { match });
    return;
  }

  const songDetailMatch = pathname.match(/^\/api\/catalog\/songs\/([^/]+)$/);
  if (request.method === 'GET' && songDetailMatch) {
    const song = repository.getSongDetail(decodeURIComponent(songDetailMatch[1]));
    if (!song) {
      writeJson(response, 404, {
        error: {
          code: 'song_not_found',
          message: 'Song was not found in the public catalog.'
        }
      });
      return;
    }

    writeJson(response, 200, { song });
    return;
  }

  writeJson(response, 404, {
    error: {
      code: 'not_found',
      message: 'Route was not found.'
    }
  });
}

function isCatalogPath(pathname) {
  return pathname === '/healthz' || pathname.startsWith('/api/catalog');
}

function writeJson(response, statusCode, payload) {
  response.writeHead(statusCode, {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store'
  });
  response.end(`${JSON.stringify(payload)}\n`);
}

module.exports = {
  createCatalogServer
};
