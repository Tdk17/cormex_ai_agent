import { db } from '../infra/db.js';

export async function recordAudit(input: {
  workspaceId: string;
  actorType: 'human' | 'agent' | 'system';
  actorId?: string | null;
  action: string;
  resourceName?: string | null;
  beforeState?: unknown;
  afterState?: unknown;
  reason?: string | null;
  result: 'success' | 'blocked' | 'failed';
  correlationId?: string | null;
}): Promise<void> {
  await db.query(
    `INSERT INTO xv_audit_logs
      (workspace_id, actor_type, actor_id, action, resource_name,
       before_state, after_state, reason, result, correlation_id)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`,
    [
      input.workspaceId,
      input.actorType,
      input.actorId ?? null,
      input.action,
      input.resourceName ?? null,
      input.beforeState === undefined ? null : JSON.stringify(input.beforeState),
      input.afterState === undefined ? null : JSON.stringify(input.afterState),
      input.reason ?? null,
      input.result,
      input.correlationId ?? null,
    ],
  );
}
