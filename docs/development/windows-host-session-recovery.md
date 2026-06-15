
# Windows Host Session Recovery Shell

Wave 5D adds unclean-shutdown recovery and stale-session restore/discard preview flows.

## Included

- unclean shutdown recovery prompt preview
- restore-session flow preview
- discard-stale-session flow preview
- rotation-rule test markers
- estimated-wait test markers
- crash-recovery test markers

## Safety boundary

Wave 5D does not restore real sessions, discard real sessions, write files, write show-session records, write rotation records, or change live show state. It is UI, documentation, and test-fixture work only.
