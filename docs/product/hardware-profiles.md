# Hardware Profiles

These profiles define first-pass planning targets. Recheck them before packaging, load testing, or buying hardware.

## Minimum live-show host laptop

- 64-bit Windows laptop meeting the supported-platform policy.
- 4 physical CPU cores or better.
- 16 GB RAM minimum.
- 512 GB SSD minimum for the operating system, application, logs, and local working space.
- Separate authorized-media storage sized for the operator's catalog.
- Stable audio output interface suitable for the venue sound system.
- HDMI or equivalent external-display output.
- Reliable power connection and backup-friendly storage health.

## Recommended live-show host laptop

- Current-generation 6+ core CPU.
- 32 GB RAM.
- 1 TB internal SSD plus dedicated authorized-media storage.
- Tested audio device and external display path before the show.

## Minimum HQ server profile

- 4 vCPU or better.
- 8 GB RAM minimum.
- 250 GB SSD minimum for operating system, application data, logs, and database working space.
- Authorized-media storage sized separately from application storage.
- Automated backups to a separate device or storage account.
- UPS-backed power where the server is on premises.

## Recommended HQ server profile

- 8 vCPU.
- 16 GB RAM or more.
- Mirrored or redundant SSD storage for metadata.
- Capacity-planned media storage with checksums, backup, and restore drills.

## Wave 0A limitation

These are planning notes only. No host app, server runtime, synchronization, playback, media storage, or backup implementation is added in this PR.
