# System Context

Wave 0B defines the boundaries between future components without implementing the components themselves.

```mermaid
flowchart LR
  Host["Windows host app\nlocal show control"]:::core
  LocalStore["Local host storage\nfuture catalog and show cache"]:::local
  HQ["HQ server\nfuture admin, catalog, sync, reports"]:::server
  DB["Local development DB\nPostgres container only"]:::infra
  Cache["Local development cache\nRedis container only"]:::infra
  RequestWeb["Request web app\nfuture guest request UI"]:::edge
  OBS["OBS companion\nfuture optional output events"]:::optional
  Replay["Replay boundary\nfuture optional event adapter"]:::optional

  Host --> LocalStore
  Host -. "future authorized sync only" .-> HQ
  HQ -. "future metadata persistence" .-> DB
  HQ -. "future development cache" .-> Cache
  RequestWeb -. "future request APIs" .-> HQ
  Host -. "future display/status events" .-> OBS
  Host -. "future approved performance events" .-> Replay

  classDef core fill:#f7fbff,stroke:#2f5f8f,color:#10243a
  classDef local fill:#f8fff7,stroke:#3f7b44,color:#17351a
  classDef server fill:#fffdf5,stroke:#8a6d1d,color:#3a2b00
  classDef edge fill:#f9f7ff,stroke:#67509c,color:#241942
  classDef optional fill:#fff8f8,stroke:#9c5757,color:#421b1b
  classDef infra fill:#f7f7f7,stroke:#666,color:#222
```

## Boundary rules

- The Windows host app remains the live-show authority and must continue operating if HQ, request web, OBS, Replay, or internet access is unavailable.
- HQ server work is future optional support for catalog metadata, synchronization, requests, reports, and administration. Wave 0B adds no HQ API implementation.
- Request web is a future guest-facing surface. Wave 0B adds no mobile request screens or request submission behavior.
- OBS and Replay remain optional event boundaries. Wave 0B defines contract shapes only.
- Local development Postgres and Redis containers are placeholders for future server work and do not include production schemas or migrations.

## Wave 0B limitation

This document is architecture only. It does not start HQ catalog database work, production APIs, Windows host features, playback, synchronization, request screens, OBS integration, or Replay integration.
