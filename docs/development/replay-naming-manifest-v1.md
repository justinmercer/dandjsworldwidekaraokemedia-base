# Replay Naming Manifest v1

Replay Naming Manifest v1 defines the next safe local planning step for karaoke replay clips.

The goal is to turn reviewed clip plan entries into proposed clip names and lower-left title text before any media work is built.

## Proposed naming pattern

    {event-date}-{venue}-{clip-number}-{singer}-{song}-{artist}

Example:

    2026-06-15-smoke-test-venue-001-jane-dont-stop-believin-journey

## Proposed lower-left title fields

Each clip should carry:

- singer display name
- song title
- artist name
- lower-left title text
- review status

## Intended workflow

1. Generate Replay Media Intake v1.
2. Generate Replay Clip Plan v1.
3. Generate Replay Checklist v1.
4. Generate Replay Publish Readiness v1.
5. Generate a naming manifest from approved clip planning data.
6. Use the naming manifest as input for a later rendering/export worker.

## Safety boundary

This is a planning document only.

It does not open media files, read media metadata, split media, transcode media, render overlays, upload anything, publish anything, call external services, perform song recognition, identify people in video, or read/write singer profiles.
