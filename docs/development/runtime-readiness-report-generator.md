
# Runtime Readiness Report Generator

This adds the first real local runtime utility after the static shell backlog: a PowerShell readiness report generator.

## Command

Run:

    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-readiness-report.ps1

To include the full smoke test before writing the report:

    powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate-readiness-report.ps1 -RunSmoke

## Output

By default, the script writes:

    reports/readiness/latest-readiness-report.md

## What it does

- reads docs/MASTER-BACKLOG-577.md
- counts checked and unchecked KARA tasks
- records current Git branch and commit
- records whether the working tree is clean or dirty
- optionally runs the repo smoke test when -RunSmoke is supplied
- writes a local Markdown readiness report

## Safety boundary

This script does not play media, control devices, change displays, change router settings, call APIs, read or write databases, provision cloud resources, implement face recognition, or process biometric data.
