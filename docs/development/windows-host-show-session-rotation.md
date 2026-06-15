
# Windows Host Show Session and Rotation Shell

Wave 5B adds the show-session and rotation-state shell for the Windows host.

## Included

- show-session model shell
- show start and end timestamp preview
- venue association preview
- active rotation state preview
- queued songs per singer preview
- current singer state preview
- up-next state preview
- temporary disable state preview
- skip state preview
- priority insert preview
- drag-and-drop ordering placeholder
- fair-round ordering rules
- configurable rotation policies
- estimated wait calculations
- rotation preview

## Safety boundary

Wave 5B does not write show-session records, write rotation records, change singer state, change live order, persist rotation actions, or autosave session snapshots. It is UI, documentation, and test-fixture work only.
