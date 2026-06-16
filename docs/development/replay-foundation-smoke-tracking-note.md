# Replay Foundation Smoke Tracking Note

Replay Media Intake v1 and Replay Clip Plan v1 each include focused smoke tests:

- `scripts/generate-replay-media-intake-smoke-test.ps1`
- `scripts/generate-replay-clip-plan-smoke-test.ps1`

The root `scripts/smoke-test.ps1` still validates the completed foundation backlog and legacy required file set.

A later housekeeping change can add the Replay v1 files to the root smoke-test required file list after the new replay planning files settle. Until then, use the focused replay generator smoke tests before merging replay runtime changes.

## Safe validation commands

    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-replay-media-intake-smoke-test.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-replay-clip-plan-smoke-test.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\smoke-test.ps1

## Safety reminder

These replay foundation tools create planning records only. They do not open, scan, split, transcode, upload, publish, recognize songs, identify people in video, or process biometric data.
