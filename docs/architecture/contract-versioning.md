# Contract Versioning

The initial shared contract version is `v1`.

## Version placement

- Schema filenames use `.v1.schema.json`.
- Schema `$id` values include `/v1/`.
- Payloads include `contractVersion` with the constant value `v1`.

## Compatibility rules

Within a major version, later changes should be additive:

- Add optional fields when possible.
- Do not rename or remove required fields without a new major version.
- Do not change enum meanings without a new major version.
- Do not repurpose identifiers or timestamps.
- Keep host-app offline compatibility in mind before requiring new server behavior.

## Breaking changes

A breaking shared contract change requires:

- An ADR describing why the change is needed.
- A new major version such as `v2`.
- A migration or compatibility plan for older host versions.
- CI updates that validate both supported versions during the overlap window.

## Wave 1A limitation

Versioning is defined for schemas only. No generated clients or production compatibility negotiation are added in this wave.
