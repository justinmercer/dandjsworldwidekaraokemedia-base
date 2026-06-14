
# Windows Host CI and Smoke Tests

Wave 3G adds CI-visible static checks and smoke tests for the Windows host shell.

## Included checks

- static host shell compile check
- startup smoke test
- clean-shutdown smoke test
- settings migration smoke test
- demo-mode screenshot checklist

## Safety boundary

These checks inspect text, JavaScript syntax, and UI markers only. They do not package the app, launch media playback, scan folders, write diagnostics exports, transfer files, delete files, or connect to external services.
