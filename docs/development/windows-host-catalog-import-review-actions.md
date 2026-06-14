
# Windows Host Catalog Import Review Actions

Wave 4B extends the catalog-import wizard shell with review states, safe review actions, audit-log preview, and test fixtures.

## Included

- needs manual review state
- skip for now action
- mark preferred version action
- keep both versions action
- merge duplicate records preview
- safe confirmation before merge preview
- import audit logging preview
- demo fixture JSON for tests only
- catalog-import tests
- malformed-filename tests
- duplicate-detection tests
- alternate-version tests
- cancellation tests

## Safety boundary

Wave 4B is UI, documentation, and test fixture work only. It does not write catalog records, merge records, read media files, move files, or change operator folders.
