# Development Storage Mounts

The HQ catalog stores metadata and opaque storage-relative keys only. Real karaoke files, absolute paths, private URLs, venue network details, and credentials must not be committed.

## Local placeholder root

Use a local development root outside source control for any operator-authorized test media you own:

```powershell
$env:MEDIA_STORAGE_ROOT = "C:\dandjs-local-authorized-media-placeholder"
```

The repository `.gitignore` blocks common media extensions and local storage folders. Keep this root out of the repo and out of pull requests.

## Storage-relative keys

Catalog rows may store opaque relative keys such as:

```text
demo-catalog/opening/primary
```

Do not store:

- absolute Windows paths
- UNC paths
- parent-directory traversal
- private URLs
- venue router or network-share details
- real customer, singer, or venue data

## Public API boundary

Public catalog routes must never expose `storageRelativeKey`, checksums, or filesystem paths. Those values are internal metadata for future synchronization and remain protected from guest-facing reads.
