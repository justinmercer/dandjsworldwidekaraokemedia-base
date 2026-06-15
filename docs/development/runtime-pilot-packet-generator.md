# Runtime Pilot Packet Generator

This adds a safe local runtime utility that creates one Markdown packet for pilot preparation and review.

## Command

Generate the packet only:

    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-pilot-packet.ps1

Generate readiness and feedback summaries first, then build the packet:

    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-pilot-packet.ps1 -RunReports

## Output

By default, the script writes:

    reports/pilot-packet/latest-pilot-packet.md

## What it does

- records current Git branch, commit, and working tree state
- counts checked and unchecked KARA backlog tasks
- reports whether readiness and feedback reports exist
- lists operator documents needed for a pilot
- writes a local Markdown pilot packet
- optionally runs the existing local readiness and feedback report generators

## Safety boundary

This script does not play media, control devices, change display settings, change router settings, call APIs, make network requests, read or write databases, read or write singer profiles, move/copy/rename/delete media files, use cloud services, implement face recognition, or process biometric data.
