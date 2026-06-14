# Windows Host Shell

This is the first Windows host application shell for D & J's Karaoke.

## Wave 3A scope

This shell is intentionally local-first and safe. It provides the first desktop host layout and placeholders only.

Included:

- main host window shell
- dark premium nightlife theme
- navigation structure
- show dashboard layout
- rotation placeholder
- now-playing placeholder
- incoming-request placeholder
- song-search placeholder
- sync-health placeholder
- playback-control placeholders
- venue selector
- current-show status indicator
- online, local-only, and offline status indicators

Not included yet:

- real playback
- real media scanning
- real file transfer
- real file deletion
- real local SQLite database
- real OBS companion connection
- real Replay integration
- real singer/request workflows

## UI framework decision

Wave 3A uses a static local WebView-style shell. The intended Windows path is a WebView2 desktop host with local assets. This keeps the live-show UI local-first while allowing fast iteration on the operator experience.

Native packaging, runtime bootstrap, and compile checks are deferred to later host-app backlog items.

## Preview

Open `src/index.html` locally in a browser for a safe visual preview.


## Wave 3B additions

Wave 3B adds UI-only placeholders for OBS companion and Replay status, keyboard shortcut infrastructure, a keyboard shortcut help dialog, and browser-local settings persistence.

These are display and preference placeholders only. They do not connect to OBS, connect to Replay, play media, scan media, transfer files, or delete files.


## Wave 3D additions

Wave 3D adds safe demo mode, demo data, first-run setup, display-only folder and server settings, local request-server settings, and UI scaling.

These features do not scan folders, connect to servers, play media, transfer files, or delete files.


## Wave 3E additions

Wave 3E adds loading, empty, and error states, plus safe toast notifications and a confirmation-dialog pattern.

These are UI-only patterns and do not perform media, file, playback, sync, OBS, or Replay actions.


## Wave 3F additions

Wave 3F adds safe error dialogs, toast follow-up, a local activity log panel, diagnostics export preview, and host build documentation.

These are UI/docs placeholders and do not write diagnostics files or perform media, file, playback, sync, OBS, or Replay actions.


## Wave 3G additions

Wave 3G adds CI-visible static compile checks, startup smoke tests, clean-shutdown smoke tests, settings migration checks, and a demo-mode screenshot checklist.

These tests and docs do not package the app, automate screenshots, scan folders, play media, transfer files, delete files, or connect to external services.
