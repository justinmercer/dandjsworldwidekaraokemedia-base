# Runtime Show Archive Manifest Generator

This adds a safe local runtime utility that creates a post-show archive manifest for pilot karaoke nights.

## Command

Generate the default manifest:

    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-show-archive-manifest.ps1

Generate a manifest with show details:

    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-show-archive-manifest.ps1 -EventDate "2026-06-15" -VenueName "Venue Name" -HostName "Host Name" -RecordingLabel "Main camera recording"

## Output

By default, the script writes:

    reports/show-archive/latest-show-archive-manifest.md

## What it does

- records show date, venue, host, and recording label
- records current Git branch, commit, and working tree state
- writes a local Markdown checklist for post-show archive review
- creates manual placeholders for future processing review

## Safety boundary

This script does not scan folders, open media files, read media metadata, move/copy/rename/delete media files, upload anything, call APIs, make network requests, read or write databases, read or write singer profiles, use cloud services, implement face recognition, or process biometric data.
