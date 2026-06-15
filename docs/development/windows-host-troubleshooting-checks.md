
# Windows Host Troubleshooting Checks

Wave 6E adds preview-only checks and troubleshooting documentation for live-show operation.

## Included

- playback-control test preview
- external-display state test preview
- monitor reconnect test preview
- keyboard shortcut test preview
- live-show playback troubleshooting documentation

## Operator troubleshooting checklist

1. Confirm the host shell is still responsive.
2. Confirm preview-only controls did not change live state.
3. Confirm the current session and rotation notes are visible.
4. Avoid changing monitor, camera, or audio routing during an active song.
5. Save notes before restarting the host shell.
6. Restart only the host shell unless a later runbook says otherwise.

## Safety boundary

Wave 6E does not run real playback, change external-display state, reconnect monitors, register global keyboard hooks, read media files, control the live show, or write runtime state.
