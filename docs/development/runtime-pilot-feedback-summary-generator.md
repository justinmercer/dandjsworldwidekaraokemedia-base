
# Runtime Pilot Feedback Summary Generator

This adds a safe local runtime utility that turns a local pilot feedback Markdown file into a local Markdown summary.

## Command

Run with the default feedback form:

    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-pilot-feedback-summary.ps1

Run with a custom feedback file:

    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-pilot-feedback-summary.ps1 -InputPath .\my-feedback.md

## Output

By default, the script writes:

    reports/pilot-feedback/latest-pilot-feedback-summary.md

## What it does

- reads one local Markdown feedback file
- counts lines and filled content lines
- finds second-level Markdown sections
- scans for blocker, confusion, and improvement keywords
- records local Git branch, commit, and working tree state
- writes a local Markdown summary report

## Safety boundary

This script does not submit feedback, call APIs, make network requests, read or write databases, read or write singer profiles, move/copy/rename/delete media files, or use cloud services.
