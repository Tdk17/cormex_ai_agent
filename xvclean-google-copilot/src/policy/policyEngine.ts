import { db } from '../infra/db.js';

export type PolicyDecision = {
  allowed: boolean;
  requiresApproval: boolean;
  reason: string;
};

type PolicyRow = {
  max_daily_budget_micros: string;
  max_budget_change_percent: string;
  protected_campaign_resource_names: string[];
  allow_auto_pause: boolean;
  allow_auto_budget_change: boolean;
};

async function getPolicy(workspaceId: string): Promise<PolicyRow> {
  const result = await db.query(
    `SELECT max_daily_budget_micros, max_budget_change_percent,
            protected_campaign_resource_names, allow_auto_pause, allow_auto_budget_change
       FROM xv_policy_settings WHERE workspace_id = $1`,
    [workspaceId],
  );
  return result.rows[0] ?? {
    max_daily_budget_micros: '0',
    max_budget_change_percent: '0',
    protected_campaign_resource_names: [],
    allow_auto_pause: false,
    allow_auto_budget_change: false,
  };
}

export async function evaluateCampaignPause(input: {
  workspaceId: string;
  campaignResourceName: string;
  approvedByHuman: boolean;
}): Promise<PolicyDecision> {
  const policy = await getPolicy(input.workspaceId);
  if (policy.protected_campaign_resource_names.includes(input.campaignResourceName)) {
    return { allowed: false, requiresApproval: false, reason: 'Campaign is protected by policy.' };
  }
  if (input.approvedByHuman) return { allowed: true, requiresApproval: false, reason: 'Human approval supplied.' };
  if (policy.allow_auto_pause) return { allowed: true, requiresApproval: false, reason: 'Auto-pause enabled by workspace policy.' };
  return { allowed: false, requiresApproval: true, reason: 'Pause requires human approval.' };
}

export async function evaluateBudgetChange(input: {
  workspaceId: string;
  currentAmountMicros: bigint;
  proposedAmountMicros: bigint;
  approvedByHuman: boolean;
}): Promise<PolicyDecision> {
  const policy = await getPolicy(input.workspaceId);
  if (input.proposedAmountMicros <= 0n) {
    return { allowed: false, requiresApproval: false, reason: 'Budget must be positive.' };
  }
  if (input.approvedByHuman) {
    const ceiling = BigInt(policy.max_daily_budget_micros || '0');
    if (ceiling > 0n && input.proposedAmountMicros > ceiling) {
      return { allowed: false, requiresApproval: false, reason: 'Proposed budget exceeds absolute workspace ceiling.' };
    }
    return { allowed: true, requiresApproval: false, reason: 'Human approval supplied within absolute ceiling.' };
  }
  if (!policy.allow_auto_budget_change) {
    return { allowed: false, requiresApproval: true, reason: 'Automatic budget changes are disabled.' };
  }

  const ceiling = BigInt(policy.max_daily_budget_micros || '0');
  if (ceiling <= 0n || input.proposedAmountMicros > ceiling) {
    return { allowed: false, requiresApproval: true, reason: 'Proposed budget is above the automatic ceiling.' };
  }

  if (input.currentAmountMicros <= 0n) {
    return { allowed: false, requiresApproval: true, reason: 'Current budget is unavailable; human approval required.' };
  }

  const delta = input.proposedAmountMicros > input.currentAmountMicros
    ? input.proposedAmountMicros - input.currentAmountMicros
    : input.currentAmountMicros - input.proposedAmountMicros;
  const changePercent = Number(delta * 10_000n / input.currentAmountMicros) / 100;
  const limitPercent = Number(policy.max_budget_change_percent || '0');

  if (limitPercent <= 0 || changePercent > limitPercent) {
    return { allowed: false, requiresApproval: true, reason: `Budget change ${changePercent}% exceeds automatic limit ${limitPercent}%.` };
  }
  return { allowed: true, requiresApproval: false, reason: 'Budget change is within configured automatic limits.' };
}
