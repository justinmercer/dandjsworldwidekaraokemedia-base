
# Windows Host State Patterns

Wave 3E adds safe UI-only state and feedback patterns to the Windows host shell.

## Included

- loading state
- empty state
- error state
- toast notification region
- confirmation-dialog pattern

## Safety boundary

The confirmation dialog is a pattern only. It does not perform destructive actions, media actions, file actions, playback, sync execution, OBS actions, or Replay actions.

The toast system is local UI feedback only.
