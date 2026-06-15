
# OBS Companion and Replay Reliability Boundary Shell

Wave 10B adds static reliability and isolation fixtures for OBS companion exports and future Replay integration planning.

## Included

- retry-safe event queue preview
- backoff for companion outages preview
- mock companion receiver preview
- companion-isolation tests preview
- companion failures never interrupt playback rule
- existing separate-recording-computer topology documentation
- OBS WebSocket port configuration as an operator setting preview
- future Replay adapter interface preview
- minimal Replay event fields preview
- mock Replay adapter preview
- retry expectations for Replay preview
- failure-isolation rules for Replay preview

## Safety boundary

Wave 10B does not connect to OBS, open WebSocket connections, send network requests, call Replay, control playback, write retry queues, write audit history, write runtime settings, or start timers.
