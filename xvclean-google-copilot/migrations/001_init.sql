CREATE TABLE IF NOT EXISTS xv_google_connections (
  workspace_id TEXT PRIMARY KEY,
  google_email TEXT,
  refresh_token_encrypted TEXT NOT NULL,
  scopes TEXT[] NOT NULL DEFAULT '{}',
  google_ads_customer_id TEXT,
  ga4_property_id TEXT,
  search_console_site_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS xv_metric_snapshots (
  id BIGSERIAL PRIMARY KEY,
  workspace_id TEXT NOT NULL,
  source TEXT NOT NULL,
  metric_key TEXT NOT NULL,
  dimensions JSONB NOT NULL DEFAULT '{}'::jsonb,
  metrics JSONB NOT NULL DEFAULT '{}'::jsonb,
  period_start DATE,
  period_end DATE,
  captured_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_xv_metrics_workspace_source_captured
  ON xv_metric_snapshots(workspace_id, source, captured_at DESC);

CREATE TABLE IF NOT EXISTS xv_recommendations (
  id UUID PRIMARY KEY,
  workspace_id TEXT NOT NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  evidence JSONB NOT NULL DEFAULT '{}'::jsonb,
  proposed_action JSONB NOT NULL DEFAULT '{}'::jsonb,
  expected_impact JSONB NOT NULL DEFAULT '{}'::jsonb,
  risk_level TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  decided_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_xv_recommendations_workspace_status
  ON xv_recommendations(workspace_id, status, created_at DESC);

CREATE TABLE IF NOT EXISTS xv_audit_logs (
  id BIGSERIAL PRIMARY KEY,
  workspace_id TEXT NOT NULL,
  actor_type TEXT NOT NULL,
  actor_id TEXT,
  action TEXT NOT NULL,
  resource_name TEXT,
  before_state JSONB,
  after_state JSONB,
  reason TEXT,
  result TEXT NOT NULL,
  correlation_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_xv_audit_workspace_created
  ON xv_audit_logs(workspace_id, created_at DESC);
