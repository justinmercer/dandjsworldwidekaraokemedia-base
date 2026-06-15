
# Analytics Export and QA Scenario Preview Shell

Wave 13B adds static planning fixtures for analytics export, analytics empty states, and safe reliability scenario previews.

## Included

- CSV analytics export preview
- analytics empty states preview
- analytics tests preview
- server-unavailable test scenario preview
- venue-internet-loss test scenario preview
- local-router-only request test scenario preview
- interrupted-sync test scenario preview
- checksum-mismatch test scenario preview

## Safety boundary

Wave 13B does not export CSV files, generate analytics, start or stop servers, change internet or router settings, write request database records, interrupt sync, calculate checksums against real files, make network requests, or write files beyond static fixtures.
