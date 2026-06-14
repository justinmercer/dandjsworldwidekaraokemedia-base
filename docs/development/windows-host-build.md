
# Windows Host Build Notes

Wave 3F adds the first host app build documentation placeholder.

## Current state

The Windows host shell currently exists as a static local-first UI shell under:

```text
host/windows-host-shell
```

It can be opened for preview through `src/index.html`.

## Future build target

A later wave can wrap this shell in a Windows desktop runtime and add packaged build output.

## Safety boundary

This document does not introduce packaging, installers, auto-updates, media scanning, playback, or file-system actions.
