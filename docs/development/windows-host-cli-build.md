# Windows Host Command-Line Build

There is no Windows host project in Wave 1A. This page records the expected command-line build shape for the later host wave.

## Today

Validate foundation checks:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-test.ps1
```

The script skips host build steps until a solution or project file exists.

## Later

When the host app is added, this page should include:

- Required .NET SDK or desktop runtime.
- Restore command.
- Build command.
- Test command.
- Packaging command if applicable.
- Demo mode launch command.
- Offline validation steps before show use.

## Wave 1A limitation

No host UI, playback engine, local database, external display window, synchronization client, OBS companion, or Replay export is added here.
