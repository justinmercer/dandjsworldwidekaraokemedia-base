# Replay Checklist v1

Replay Checklist v1 turns a Replay Clip Plan v1 JSON record into a Markdown checklist that an operator can review before any later export, overlay, upload, or publishing work.

## Command

Generate the checklist from the default clip plan:

    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-replay-checklist.ps1

Generate a checklist from a specific clip plan:

    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-replay-checklist.ps1 -ClipPlanPath "reports/replay-clip-plan/latest-replay-clip-plan.json" -OutputPath "reports/replay-checklist/latest-replay-checklist.md"

## Output

By default, the script writes:

    reports/replay-checklist/latest-replay-checklist.md

## What it includes

- source clip plan id
- source intake id
- show date, venue, host, and show session id
- operator review checklist
- clip table with start, end, singer, song, artist, overlay title, privacy status, publish decision, and notes
- safety boundary reminders

## Intended workflow

1. Generate a Replay Media Intake v1 record.
2. Generate a Replay Clip Plan v1 record.
3. Fill in or review clip plan placeholders.
4. Generate the Replay Checklist v1 Markdown file.
5. Use the checklist to confirm singer/song/artist/overlay/privacy/publish decisions before later processing.

## Safety boundary

This checklist reads the clip plan JSON only.

It does not scan folders, check media existence, open media files, read media metadata, split media, transcode media, render title overlays, move/copy/rename/delete media files, upload anything, publish anything, call APIs, make network requests, read or write databases, read or write singer profiles, create or update singer accounts, auto-tag singers, use cloud services, perform song recognition, identify people in video, or process biometric data.
