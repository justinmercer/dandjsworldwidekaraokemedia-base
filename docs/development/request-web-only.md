# Run Only the Request Web App

There is no request web app implementation in Wave 1A. This page documents the intended developer workflow once the app exists.

## Today

The request-web directory contains:

- `.env.example` with safe demo placeholders.
- `dev-proxy.config.json` describing the future local proxy shape.

Validate the proxy placeholder with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\lint-web.ps1
```

## Later

When the app is added, this page should include:

- Install command.
- Development server command.
- Local proxy command.
- Test and lint commands.
- Demo mode setup.
- How to run without a live HQ API by using safe mock data.

## Wave 1A limitation

No mobile request screens, QR flow, PWA shell, kiosk mode, request submission behavior, or production proxy is added here.
