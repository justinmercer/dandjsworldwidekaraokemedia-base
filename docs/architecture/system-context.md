# System Context

Wave 2A keeps the component boundaries and adds HQ-side host registration plus sync-manifest planning while preserving local-first show control.

```mermaid
flowchart LR
  Host["Windows host app\nlocal show control"]:::core
  LocalStore["Local host storage\nfuture catalog and show cache"]:::local
  HQ["HQ server\ncatalog API, controls,\nhost sync planning"]:::server
  DB["Local development DB\nPostgres catalog schema"]:::infra
  Cache["Local development cache\nRedis container only"]:::infra
  RequestWeb["Request web app\nfuture guest request UI"]:::edge
  OBS["OBS companion\nfuture optional output events"]:::optional
  Replay["Replay boundary\nfuture optional event adapter"]:::optional

  Host --> LocalStore
  Host -. "protected registration and manifest planning" .-> HQ
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
- HQ server work now includes public catalog reads, protected development catalog controls, protected host registration, heartbeat state, admin host status, deterministic host manifests, and review-first manifest diffs backed by PostgreSQL when `DATABASE_URL` is configured.
- Request web is a future guest-facing surface. Wave 2A adds no mobile request screens or request submission behavior.
- OBS and Replay remain optional event boundaries. Wave 2A adds no implementation for either integration.
- Local development Postgres includes authorized-catalog, catalog-controls, host-device, and sync-planning metadata schema with synthetic seed SQL.

## Wave 2A limitation

This batch does not add full staff authentication, host downloading, local file transfer, Windows host UI, playback, synchronization progress/error reporting, cleanup deletion execution, request screens, OBS integration, Replay integration, external-source acquisition workflows, real karaoke media, credentials, private URLs, venue network details, or personal singer data.
