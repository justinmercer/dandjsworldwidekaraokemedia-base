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


## Wave 4A additions

Wave 4A adds the catalog-import wizard shell, supported-file-type detection preview, filename parsing preview, manual correction, batch review, duplicate and alternate-version warning displays, import progress display, cancellation preview, error summaries, and review queue placeholder.

This wave does not scan folders, read media files, write catalog records, merge duplicates, move files, delete files, or execute rollback.


## Wave 4B additions

Wave 4B adds import review action placeholders, needs-manual-review state, skip-for-now, mark-preferred, keep-both, duplicate merge preview, safe merge confirmation preview, audit-log preview, and test-only catalog import fixtures.

This wave does not write catalog records, merge records, read media files, move files, or change operator folders.


## Wave 4C additions

Wave 4C adds the Siglos migration wizard shell, export preview sections, migration validation preview, duplicate warnings, backup-first messaging, migration summary report preview, and test-only Siglos fixture data.

This wave does not read Siglos files, write records, move files, or change local preferences.


## Wave 5A additions

Wave 5A adds the singer profile model shell, privacy-safe optional contact preview, staff-only notes preview, favourites and history preview, remembered key-change preview, duet/group support, alias merge warning preview, and repeat singer warning preview.

This wave does not write singer records, merge records, expose contact details publicly, or change rotation.


## Wave 5B additions

Wave 5B adds the show-session model shell, timestamp and venue previews, active rotation state, queued songs per singer, current/up-next state, temporary disable and skip states, priority insert, drag ordering placeholder, fair-round rules, configurable policies, estimated wait calculations, and rotation preview.

This wave does not write show-session records, write rotation records, change singer state, or change live rotation order.


## Wave 5C additions

Wave 5C adds call singer, singer not ready, move to next round, remove from tonight, restore singer, completed performance record preview, show notes, manual session snapshot preview, and autosave trigger preview.

This wave does not change live rotation, write history, write files, write session snapshots, or persist autosave.


## Wave 5D additions

Wave 5D adds unclean-shutdown recovery prompts, restore-session preview, discard-stale-session preview, rotation-rule test markers, estimated-wait test markers, and crash-recovery test markers.

This wave does not restore or discard real sessions, write files, write records, or change live show state.
