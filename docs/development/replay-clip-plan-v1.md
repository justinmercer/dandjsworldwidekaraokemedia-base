# Replay Clip Plan v1

Replay Clip Plan v1 is the manual planning layer after Replay Media Intake v1.

It prepares candidate karaoke replay clips before any actual media splitting, title overlay rendering, singer tagging, upload, or publishing work begins.

## Command

Generate the default clip plan:

    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-replay-clip-plan.ps1

Generate a clip plan with show details and a custom number of placeholder clips:

    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-replay-clip-plan.ps1 -EventDate "2026-06-15" -VenueName "Venue Name" -HostName "Host Name" -ShowSessionId "show-session-id" -SourceIntakeId "replay-intake-id" -ClipCount 10

## Output

By default, the script writes:

    reports/replay-clip-plan/latest-replay-clip-plan.json

## Contract

The JSON record follows:

    packages/contracts/schemas/replay-clip-plan.v1.schema.json

The record includes:

- clip plan id and creation time
- source intake id
- show date, venue, host, and show session id
- manual placeholder clips
- approximate start and end placeholders
- singer, song, artist, and overlay title placeholders
- privacy status and publish decision placeholders
- plan-level review statuses
- explicit processing boundary flags

## Intended workflow

1. Generate a Replay Media Intake v1 record for the full-show recording.
2. Generate a Replay Clip Plan v1 record with the expected number of candidate clips.
3. Manually review the full recording and fill in start/end times.
4. Manually confirm singer names, song titles, and artist names.
5. Manually confirm lower-left overlay title text.
6. Review privacy and permission status.
7. Approve only the clips that are safe to publish.
8. Build later automation only after this manual workflow is proven reliable.

## Safety boundary

This clip plan is a manual planning record only.

It does not scan folders, check media existence, open media files, read media metadata, split media, transcode media, render title overlays, move/copy/rename/delete media files, upload anything, publish anything, call APIs, make network requests, read or write databases, read or write singer profiles, create or update singer accounts, auto-tag singers, use cloud services, perform song recognition, identify people in video, or process biometric data.
