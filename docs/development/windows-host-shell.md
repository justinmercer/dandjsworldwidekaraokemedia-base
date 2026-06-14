
# Windows Host Shell

Wave 3 starts the Windows host application shell without adding risky live-show behavior.

## UI framework choice

The selected path is a Windows WebView2 desktop shell with local assets.

## Wave 3A

Wave 3A added the first safe dashboard shell, navigation, theme, venue selector, show status, core dashboard placeholders, and online/local-only/offline indicators.

## Wave 3B

Wave 3B adds safe UI-only infrastructure for:

- OBS companion connection indicator placeholder.
- Replay integration indicator placeholder.
- Keyboard shortcut infrastructure.
- Keyboard shortcut help dialog.
- Browser-local settings persistence for display preferences.

## Current safety boundary

Wave 3B does not add playback, real media file access, file transfer, file deletion, local SQLite persistence, real OBS connection behavior, real Replay connection behavior, or server dependency for live operation.

## Preview command

```powershell
Start-Process ".\\host\\windows-host-shell\\src\\index.html"
```

## Readiness command

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\\scripts\\host-shell-smoke-test.ps1
```
