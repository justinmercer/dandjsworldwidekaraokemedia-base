
# Reliability Scenario Preview Shell

Wave 13C adds static planning fixtures for reliability scenario previews.

## Included

- insufficient-storage test scenario preview
- host-restart recovery test scenario preview
- unclean-shutdown recovery test scenario preview
- OBS companion outage test scenario preview
- Replay adapter outage test scenario preview
- external-monitor disconnect test scenario preview
- empty-library startup test scenario preview
- empty-show startup test scenario preview

## Safety boundary

Wave 13C does not probe storage, run restart commands, run shutdown commands, connect to OBS, connect to Replay, probe monitors, read catalog databases, read show databases, make network requests, or write files beyond static fixtures.
