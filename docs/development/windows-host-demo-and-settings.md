
# Windows Host Demo Mode and Settings

Wave 3D adds safe host-shell placeholders for demo mode, first-run setup, local authorized media folder settings, HQ server URL settings, local request-server settings, and UI scaling.

## Demo mode

Demo data lives at:

```text
host/windows-host-shell/demo-data/host-demo-data.json
```

The file contains demo singers, songs, requests, venue details, and display settings only. It does not contain media files, file paths to real media, credentials, private network details, or secrets.

## First-run setup

The first-run setup wizard is a UI placeholder. It explains setup steps and stores display preferences only.

## Local authorized media folder setting

The folder setting is a display-only placeholder in Wave 3D. It does not scan the folder or read files.

## Server URL and local request-server settings

These are display-only placeholders. The live-show shell remains local-first and does not require server access.

## UI scaling

The shell supports safe UI scaling values of 90%, 100%, 110%, and 125%.
