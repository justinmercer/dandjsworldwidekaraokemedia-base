
# Windows Host Shell

Wave 3A starts the Windows host application shell without adding risky live-show behavior.

## UI framework choice

The selected path is a Windows WebView2 desktop shell with local assets.

Reasoning:

- The operator UI can be iterated quickly with HTML, CSS, and JavaScript.
- The live-show shell can load local assets without internet access.
- A future Windows wrapper can host these assets through WebView2.
- Playback, media scanning, local SQLite, OBS companion, and Replay integration can remain separate modules behind safe boundaries.

## Current safety boundary

Wave 3A does not add:

- playback
- real media file access
- file transfer
- file deletion
- local SQLite persistence
- OBS connection behavior
- Replay connection behavior
- server dependency for live operation

## Preview command

Open the static shell locally:

```powershell
Start-Process ".\\host\\windows-host-shell\\src\\index.html"
```

## Readiness command

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\\scripts\\host-shell-smoke-test.ps1
```
