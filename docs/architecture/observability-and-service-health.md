# Observability and Service Health

Wave 0B defines observability expectations for future services without implementing service runtimes.

## Structured logging

Future services should emit JSON-line logs with at least:

- `timestamp`
- `level`
- `service`
- `environment`
- `message`
- `correlationId`
- `eventName`

Log entries must not include secrets, raw media paths, private URLs, venue network details, or unnecessary personal singer information.

The local placeholder configuration is `infra/local/observability/logging.config.json`.

## Correlation IDs

Future server API requests should use the `x-correlation-id` header.

- If a caller sends a valid correlation ID, pass it through.
- If absent, generate one at the server boundary.
- Return the correlation ID in responses.
- Include it in logs, health diagnostics, request handling, and background work spawned from the request.

The shared request context shape is `api-request-context.v1.schema.json`.

## Health endpoint contract

Future server-side services should expose a lightweight health response for liveness.

Recommended route shape:

```text
GET /healthz
```

The response shape is `service-health.v1.schema.json`.

## Readiness endpoint contract

Future server-side services should expose readiness separately from liveness.

Recommended route shape:

```text
GET /readyz
```

Readiness may check dependencies such as database and cache connectivity. A service that is alive but not ready should not receive normal traffic.

The response shape is `service-readiness.v1.schema.json`.

## Wave 0B limitation

This document and the schemas define contracts only. No server process, route handler, middleware, database check, or production monitoring integration is added in this wave.
