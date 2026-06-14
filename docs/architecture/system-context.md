# System Context

Wave 1B keeps the component boundaries and adds HQ catalog reads plus temporary protected catalog-management controls.

```mermaid
flowchart LR
  Host["Windows host app\nlocal show control"]:::core
  LocalStore["Local host storage\nfuture catalog and show cache"]:::local
  HQ["HQ server\ncatalog API and controls\nfuture full auth, sync, reports"]:::server
  DB["Local development DB\nPostgres catalog schema"]:::infra
  Cache["Local development cache\nRedis container only"]:::infra
  RequestWeb["Request web app\nfuture guest request UI"]:::edge
  OBS["OBS companion\nfuture optional output events"]:::optional
  Replay["Replay boundary\nfuture optional event adapter"]:::optional

  Host --> LocalStore
  Host -. "future authorized sync only" .-> HQ
  HQ -. "catalog migrations" .-> DB
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
- HQ server work now includes public catalog health, search, exact-match, song-detail, and alternate-version endpoints plus protected development catalog controls backed by PostgreSQL when `DATABASE_URL` is configured.
- Request web is a future guest-facing surface. Wave 1B adds no mobile request screens or request submission behavior.
- OBS and Replay remain optional event boundaries. Wave 1B adds no implementation for either integration.
- Local development Postgres includes the initial authorized-catalog schema and synthetic seed SQL.

## Wave 1B limitation

This batch does not add full staff authentication, Windows host features, playback, synchronization jobs, request screens, OBS integration, Replay integration, external-source acquisition workflows, real karaoke media, credentials, private URLs, venue network details, or personal singer data.
