# Runtime Post-Show Processing Plan Generator

This adds a safe local runtime utility that creates a post-show processing plan for D & J's Karaoke Replay pilot nights.

The plan sits after the show archive manifest and before any later clipping, title overlay, singer tagging, upload, or publishing work.

## Command

Generate the default plan:

    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-post-show-processing-plan.ps1

Generate a plan with show details:

    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-post-show-processing-plan.ps1 -EventDate "2026-06-15" -VenueName "Venue Name" -HostName "Host Name" -ShowArchiveManifestPath "reports/show-archive/latest-show-archive-manifest.md"

## Output

By default, the script writes:

    reports/post-show-processing/latest-post-show-processing-plan.md

## What it does

- records show date, venue, host, and show archive manifest path
- records whether the referenced show archive manifest file is available
- records current Git branch, commit, and working tree state
- writes required operator gates before processing
- writes a manual replay clip planning table
- writes replay processing stages for clip review, title overlays, singer account/tagging review, QA, and publishing approval
- writes future automation markers for clip splitting, song and artist detection, face matching research, and title overlays

## Safety boundary

This script does not scan folders, open media files, read media metadata, split media, transcode media, move/copy/rename/delete media files, upload anything, publish anything, call APIs, make network requests, read or write databases, read or write singer profiles, create or update singer accounts, auto-tag singers, use cloud services, perform song recognition, perform face recognition, or process biometric data.
