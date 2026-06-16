# Replay Media Intake v1

Replay Media Intake v1 is the first safe structure for recording full-show karaoke media details before any automated clipping, title overlay, singer tagging, upload, or publishing work begins.

It records operator-entered metadata only. It does not inspect or process the media files.

## Command

Generate the default intake record:

    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-replay-media-intake.ps1

Generate an intake record with show and recording details:

    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-replay-media-intake.ps1 -EventDate "2026-06-15" -VenueName "Venue Name" -HostName "Host Name" -ShowSessionId "show-session-id" -MainRecordingPath "D:\Karaoke\Venue\main.mp4" -BackupRecordingPath "D:\Karaoke\Venue\backup.mp4"

## Output

By default, the script writes:

    reports/replay-media-intake/latest-replay-media-intake.json

## Contract

The JSON record follows:

    packages/contracts/schemas/replay-media-intake.v1.schema.json

The record includes:

- intake id and creation time
- show date, venue, host, and show session id
- main and backup recording path strings entered by the operator
- initial review statuses for archive manifest, clip planning, singer/song review, overlay title review, privacy review, and publish approval
- operator notes
- explicit processing boundary flags

## Intended workflow

1. Generate a show archive manifest after the karaoke night.
2. Generate the replay media intake record with the operator-entered recording paths.
3. Confirm the main recording and backup recording manually.
4. Move into post-show processing planning.
5. Only after manual review, build later automation for clipping, title overlays, song recognition, singer tagging, and publishing.

## Safety boundary

This intake step stores paths as text only.

It does not scan folders, check media existence, open media files, read media metadata, split media, transcode media, move/copy/rename/delete media files, upload anything, publish anything, call APIs, make network requests, read or write databases, read or write singer profiles, create or update singer accounts, auto-tag singers, use cloud services, perform song recognition, perform face recognition, or process biometric data.
