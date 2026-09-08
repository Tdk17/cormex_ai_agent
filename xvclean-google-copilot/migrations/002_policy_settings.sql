CREATE TABLE IF NOT EXISTS xv_policy_settings (
  workspace_id TEXT PRIMARY KEY,
  max_daily_budget_micros BIGINT NOT NULL DEFAULT 0,
  max_budget_change_percent NUMERIC(6,2) NOT NULL DEFAULT 0,
  protected_campaign_resource_names TEXT[] NOT NULL DEFAULT '{}',
  allow_auto_pause BOOLEAN NOT NULL DEFAULT FALSE,
  allow_auto_budget_change BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON COLUMN xv_policy_settings.max_daily_budget_micros IS
  'Absolute budget ceiling. Zero means budget mutation remains approval-only.';
COMMENT ON COLUMN xv_policy_settings.max_budget_change_percent IS
  'Maximum automatic percentage change. Zero means budget mutation remains approval-only.';
