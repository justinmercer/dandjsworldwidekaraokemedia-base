DO $$
BEGIN
  CREATE TYPE hq_catalog.host_sync_control_status AS ENUM (
    'ready',
    'pending',
    'syncing',
    'verified',
    'failed',
    'review_needed',
    'paused',
    'cancelled'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE hq_catalog.host_sync_action_name AS ENUM (
    'sync_now',
    'verify_library',
    'view_missing_locally',
    'review_cleanup_candidates',
    'pause_sync',
    'resume_sync',
    'cancel_pending_noncritical'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE hq_catalog.host_sync_action_status AS ENUM (
    'queued',
    'accepted',
    'rejected',
    'completed',
    'failed'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE hq_catalog.host_sync_safety_mode AS ENUM (
    'plan_only',
    'metadata_only'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS hq_catalog.host_sync_operations (
  sync_operation_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  host_device_id uuid NOT NULL REFERENCES hq_catalog.host_devices(host_device_id) ON DELETE CASCADE,
  operation_kind text NOT NULL DEFAULT 'sync',
  status hq_catalog.host_sync_control_status NOT NULL DEFAULT 'pending',
  progress jsonb NOT NULL DEFAULT '{"totalEntries":0,"completedEntries":0,"pendingEntries":0,"failedEntries":0,"bytesTotal":0,"bytesCompleted":0,"percentComplete":0}'::jsonb,
  capacity_check jsonb NOT NULL DEFAULT '{"localFreeSpaceBytes":null,"requiredBytes":0,"isSufficient":true}'::jsonb,
  verification jsonb NOT NULL DEFAULT '{"checksumAlgorithm":"sha256","result":"not_checked"}'::jsonb,
  quarantine jsonb NOT NULL DEFAULT '{"required":false}'::jsonb,
  retry_policy jsonb NOT NULL DEFAULT '{"attempt":0,"maxAttempts":0,"nextRetryAt":null,"backoffSeconds":0}'::jsonb,
  last_error jsonb,
  pause_requested_at timestamptz,
  resume_requested_at timestamptz,
  cancel_requested_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT host_sync_operations_kind_not_blank CHECK (btrim(operation_kind) <> ''),
  CONSTRAINT host_sync_operations_progress_object CHECK (jsonb_typeof(progress) = 'object'),
  CONSTRAINT host_sync_operations_capacity_object CHECK (jsonb_typeof(capacity_check) = 'object'),
  CONSTRAINT host_sync_operations_verification_object CHECK (jsonb_typeof(verification) = 'object'),
  CONSTRAINT host_sync_operations_quarantine_object CHECK (jsonb_typeof(quarantine) = 'object'),
  CONSTRAINT host_sync_operations_retry_object CHECK (jsonb_typeof(retry_policy) = 'object'),
  CONSTRAINT host_sync_operations_last_error_object CHECK (last_error IS NULL OR jsonb_typeof(last_error) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_host_sync_operations_host_status
  ON hq_catalog.host_sync_operations(host_device_id, status, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_host_sync_operations_updated
  ON hq_catalog.host_sync_operations(updated_at DESC);

CREATE TABLE IF NOT EXISTS hq_catalog.host_sync_operator_actions (
  sync_action_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  host_device_id uuid NOT NULL REFERENCES hq_catalog.host_devices(host_device_id) ON DELETE CASCADE,
  action hq_catalog.host_sync_action_name NOT NULL,
  status hq_catalog.host_sync_action_status NOT NULL DEFAULT 'queued',
  safety_mode hq_catalog.host_sync_safety_mode NOT NULL DEFAULT 'plan_only',
  requested_by text,
  requested_at timestamptz NOT NULL DEFAULT now(),
  reason text,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT host_sync_actions_requested_by_not_blank CHECK (requested_by IS NULL OR btrim(requested_by) <> ''),
  CONSTRAINT host_sync_actions_reason_not_blank CHECK (reason IS NULL OR btrim(reason) <> ''),
  CONSTRAINT host_sync_actions_payload_object CHECK (jsonb_typeof(payload) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_host_sync_operator_actions_host_status
  ON hq_catalog.host_sync_operator_actions(host_device_id, status, requested_at DESC);

CREATE INDEX IF NOT EXISTS idx_host_sync_operator_actions_action
  ON hq_catalog.host_sync_operator_actions(action, requested_at DESC);

CREATE TABLE IF NOT EXISTS hq_catalog.host_sync_quarantine (
  sync_quarantine_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  host_device_id uuid NOT NULL REFERENCES hq_catalog.host_devices(host_device_id) ON DELETE CASCADE,
  sync_operation_id uuid REFERENCES hq_catalog.host_sync_operations(sync_operation_id) ON DELETE SET NULL,
  authorized_media_id uuid REFERENCES hq_catalog.authorized_media_files(authorized_media_id) ON DELETE SET NULL,
  reason text NOT NULL,
  verification jsonb NOT NULL DEFAULT '{}'::jsonb,
  quarantine_key text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz,
  CONSTRAINT host_sync_quarantine_reason_not_blank CHECK (btrim(reason) <> ''),
  CONSTRAINT host_sync_quarantine_key_not_blank CHECK (btrim(quarantine_key) <> ''),
  CONSTRAINT host_sync_quarantine_verification_object CHECK (jsonb_typeof(verification) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_host_sync_quarantine_host_created
  ON hq_catalog.host_sync_quarantine(host_device_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_host_sync_quarantine_unresolved
  ON hq_catalog.host_sync_quarantine(created_at DESC)
  WHERE resolved_at IS NULL;

INSERT INTO hq_catalog.schema_migrations (version, description)
VALUES ('0004', 'host sync control persistence planning')
ON CONFLICT (version) DO UPDATE
SET description = EXCLUDED.description;