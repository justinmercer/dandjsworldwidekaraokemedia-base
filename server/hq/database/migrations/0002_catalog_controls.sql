CREATE TABLE IF NOT EXISTS hq_catalog.catalog_change_audit (
  audit_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type text NOT NULL,
  entity_id uuid NOT NULL,
  action text NOT NULL,
  actor_label text NOT NULL,
  change_reason text,
  before_snapshot jsonb,
  after_snapshot jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT catalog_change_audit_entity_type_not_blank CHECK (btrim(entity_type) <> ''),
  CONSTRAINT catalog_change_audit_action_not_blank CHECK (btrim(action) <> ''),
  CONSTRAINT catalog_change_audit_actor_label_not_blank CHECK (btrim(actor_label) <> '')
);

CREATE INDEX IF NOT EXISTS idx_catalog_change_audit_entity_created
  ON hq_catalog.catalog_change_audit(entity_type, entity_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_catalog_change_audit_action_created
  ON hq_catalog.catalog_change_audit(action, created_at DESC);

INSERT INTO hq_catalog.schema_migrations (version, description)
VALUES ('0002', 'catalog controls and audit history')
ON CONFLICT (version) DO UPDATE
SET description = EXCLUDED.description;
