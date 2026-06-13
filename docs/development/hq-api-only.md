# Run Only the HQ API

There is no HQ API implementation in Wave 0B. This page documents the intended developer workflow once the API project exists.

## Today

Use the local database and cache containers only:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\start-local-stack.ps1
```

Validate the current foundation checks:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\smoke-test.ps1
```

## Later

When the HQ API project is added, this page should include:

- The project path.
- Required safe `.env.example` values.
- Build and test commands.
- Local-only ports.
- Health and readiness URLs.
- How to run without request web or host dependencies.

## Wave 0B limitation

No API routes, catalog database, migrations, authentication, synchronization endpoints, or production server features are added here.
