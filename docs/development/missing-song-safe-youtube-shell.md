
# Missing Song and Safe YouTube Preview Shell

Wave 8B adds the missing-song and safe YouTube preview shell.

## Included

- venue default request limits preview
- request-status updates back to guests preview
- request audit history preview
- missing-song state preview
- missing-song review queue preview
- authorized catalog before external search rule
- official YouTube Data API configuration placeholders
- official YouTube search integration shell
- host-reviewed missing-song workflow limit
- cached search results preview

## Safety boundary

Wave 8B does not call the YouTube Data API, perform external search, embed a YouTube player, download media, write runtime cache records, write queue records, write singer records, write audit history, update guest status, or modify venue default limits.
