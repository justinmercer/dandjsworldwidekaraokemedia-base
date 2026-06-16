# Replay Publish Readiness v1

Replay Publish Readiness v1 creates a local JSON readiness record after the replay checklist stage.

It is a final manual gate before any future export, title overlay rendering, upload, or public publishing feature is built.

## Command

Generate readiness from the default checklist and clip plan:

    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-replay-publish-readiness.ps1

Generate readiness from specific paths:

    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-replay-publish-readiness.ps1 -ClipPlanPath "reports/replay-clip-plan/latest-replay-clip-plan.json" -ChecklistPath "reports/replay-checklist/latest-replay-checklist.md" -OperatorName "Operator Name"

## Output

By default, the script writes:

    reports/replay-publish-readiness/latest-replay-publish-readiness.json

## What it includes

- readiness id and creation time
- operator name
- source checklist path
- source clip plan path
- source clip plan id
- source intake id
- show date, venue, host, and show session id
- checklist confirmation gates
- clip summaries
- publishing boundary flags

## Default behavior

Publishing is disabled by default:

    publishingAllowed = false
    approvedClipCount = 0

Every clip starts as not approved unless a later manual review workflow changes that in a separate safe step.

## Intended workflow

1. Generate Replay Media Intake v1.
2. Generate Replay Clip Plan v1.
3. Generate Replay Checklist v1.
4. Review the checklist manually.
5. Generate Replay Publish Readiness v1.
6. Build later export or publishing tools only after the readiness record format is proven.

## Safety boundary

This readiness record is local-only.

It does not scan folders, open media files, read media metadata, split media, transcode media, render title overlays, move/copy/rename/delete media files, upload anything, publish anything, call external APIs, make network requests, read platform secrets, read or write databases, read or write singer profiles, create or update singer accounts, auto-tag singers, use cloud services, perform song recognition, identify people in video, or process biometric data.
