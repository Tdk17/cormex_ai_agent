import crypto from 'node:crypto';
import express, { type NextFunction, type Request, type Response } from 'express';
import { z } from 'zod';
import { env } from './config/env.js';
import { db } from './infra/db.js';
import {
  buildGoogleAuthorizationUrl,
  exchangeAuthorizationCode,
  fetchGoogleEmail,
  refreshAccessToken,
  verifyOAuthState,
} from './google/oauth.js';
import {
  fetchCampaignBudgetState,
  fetchCampaignKpis,
  fetchCampaignState,
  setCampaignBudgetMicros,
  setCampaignStatus,
} from './google/googleAds.js';
import { fetchGa4Kpis } from './google/ga4.js';
import { fetchSearchConsoleKpis } from './google/searchConsole.js';
import {
  getGoogleConnection,
  updateGooglePropertyIds,
  upsertGoogleConnection,
} from './repositories/googleConnectionRepository.js';
import { recordAudit } from './repositories/auditRepository.js';
import { evaluateBudgetChange, evaluateCampaignPause } from './policy/policyEngine.js';

const app = express();
app.use(express.json({ limit: '256kb' }));

function safeEqual(a: string, b: string): boolean {
  const aa = Buffer.from(a);
  const bb = Buffer.from(b);
  return aa.length === bb.length && crypto.timingSafeEqual(aa, bb);
}

function requireInternal(req: Request, res: Response, next: NextFunction): void {
  const supplied = String(req.header('x-internal-api-key') ?? '');
  if (!safeEqual(supplied, env.INTERNAL_API_KEY)) {
    res.status(401).json({ error: 'unauthorized' });
    return;
  }
  next();
}

function requireWorkspace(req: Request, res: Response, next: NextFunction): void {
  const workspaceId = String(req.header('x-workspace-id') ?? '').trim();
  if (!workspaceId) {
    res.status(400).json({ error: 'x-workspace-id header is required' });
    return;
  }
  res.locals.workspaceId = workspaceId;
  next();
}

async function requireConnection(workspaceId: string) {
  const connection = await getGoogleConnection(workspaceId);
  if (!connection) {
    const error = new Error('Google is not connected for this workspace.');
    (error as Error & { status?: number }).status = 409;
    throw error;
  }
  return connection;
}

app.get('/health', async (_req, res) => {
  await db.query('SELECT 1');
  res.json({ ok: true, service: 'xvclean-google-copilot' });
});

app.get('/v1/google/oauth/start', requireInternal, requireWorkspace, (req, res) => {
  const workspaceId = String(res.locals.workspaceId);
  res.json({ authorizationUrl: buildGoogleAuthorizationUrl(workspaceId) });
});

app.get('/v1/google/oauth/callback', async (req, res) => {
  const query = z.object({ code: z.string().min(1), state: z.string().min(1) }).parse(req.query);
  const state = verifyOAuthState(query.state);
  const tokens = await exchangeAuthorizationCode(query.code);
  const email = await fetchGoogleEmail(tokens.accessToken);
  await upsertGoogleConnection({
    workspaceId: state.workspaceId,
    googleEmail: email,
    refreshToken: tokens.refreshToken,
    scopes: tokens.scope,
  });
  res.redirect(`${env.APP_ORIGIN}/integrations/google?status=connected`);
});

app.get('/v1/google/connection', requireInternal, requireWorkspace, async (_req, res) => {
  const connection = await getGoogleConnection(String(res.locals.workspaceId));
  if (!connection) {
    res.json({ connected: false });
    return;
  }
  res.json({
    connected: true,
    googleEmail: connection.googleEmail,
    scopes: connection.scopes,
    googleAdsCustomerId: connection.googleAdsCustomerId,
    ga4PropertyId: connection.ga4PropertyId,
    searchConsoleSiteUrl: connection.searchConsoleSiteUrl,
  });
});

app.put('/v1/google/properties', requireInternal, requireWorkspace, async (req, res) => {
  const body = z.object({
    googleAdsCustomerId: z.string().min(1).nullable().optional(),
    ga4PropertyId: z.string().min(1).nullable().optional(),
    searchConsoleSiteUrl: z.string().min(1).nullable().optional(),
  }).parse(req.body);
  const workspaceId = String(res.locals.workspaceId);
  await requireConnection(workspaceId);
  await updateGooglePropertyIds({ workspaceId, ...body });
  res.status(204).end();
});

app.put('/v1/policy', requireInternal, requireWorkspace, async (req, res) => {
  const body = z.object({
    maxDailyBudgetMicros: z.string().regex(/^\d+$/),
    maxBudgetChangePercent: z.number().min(0).max(100),
    protectedCampaignResourceNames: z.array(z.string()).default([]),
    allowAutoPause: z.boolean().default(false),
    allowAutoBudgetChange: z.boolean().default(false),
  }).parse(req.body);
  const workspaceId = String(res.locals.workspaceId);
  await db.query(
    `INSERT INTO xv_policy_settings
      (workspace_id, max_daily_budget_micros, max_budget_change_percent,
       protected_campaign_resource_names, allow_auto_pause, allow_auto_budget_change)
     VALUES ($1,$2,$3,$4,$5,$6)
     ON CONFLICT (workspace_id) DO UPDATE SET
       max_daily_budget_micros = EXCLUDED.max_daily_budget_micros,
       max_budget_change_percent = EXCLUDED.max_budget_change_percent,
       protected_campaign_resource_names = EXCLUDED.protected_campaign_resource_names,
       allow_auto_pause = EXCLUDED.allow_auto_pause,
       allow_auto_budget_change = EXCLUDED.allow_auto_budget_change,
       updated_at = NOW()`,
    [
      workspaceId,
      body.maxDailyBudgetMicros,
      body.maxBudgetChangePercent,
      body.protectedCampaignResourceNames,
      body.allowAutoPause,
      body.allowAutoBudgetChange,
    ],
  );
  res.status(204).end();
});

app.get('/v1/dashboard/kpis', requireInternal, requireWorkspace, async (req, res) => {
  const query = z.object({
    startDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
    endDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  }).parse(req.query);
  const workspaceId = String(res.locals.workspaceId);
  const connection = await requireConnection(workspaceId);
  const accessToken = await refreshAccessToken(connection.refreshToken);
  const warnings: string[] = [];

  const googleAds = connection.googleAdsCustomerId
    ? await fetchCampaignKpis({
        accessToken,
        customerId: connection.googleAdsCustomerId,
        startDate: query.startDate,
        endDate: query.endDate,
      })
    : (warnings.push('google_ads_customer_id_not_configured'), null);

  const ga4 = connection.ga4PropertyId
    ? await fetchGa4Kpis({
        accessToken,
        propertyId: connection.ga4PropertyId,
        startDate: query.startDate,
        endDate: query.endDate,
      })
    : (warnings.push('ga4_property_id_not_configured'), null);

  const searchConsole = connection.searchConsoleSiteUrl
    ? await fetchSearchConsoleKpis({
        accessToken,
        siteUrl: connection.searchConsoleSiteUrl,
        startDate: query.startDate,
        endDate: query.endDate,
      })
    : (warnings.push('search_console_site_url_not_configured'), null);

  res.json({ period: query, googleAds, ga4, searchConsole, warnings });
});

app.post('/v1/google-ads/campaign/status', requireInternal, requireWorkspace, async (req, res) => {
  const body = z.object({
    campaignResourceName: z.string().min(1),
    status: z.enum(['ENABLED', 'PAUSED']),
    approvedByHuman: z.boolean().default(false),
    actorId: z.string().optional(),
    reason: z.string().max(1000).optional(),
  }).parse(req.body);
  const workspaceId = String(res.locals.workspaceId);
  const correlationId = crypto.randomUUID();
  const connection = await requireConnection(workspaceId);
  if (!connection.googleAdsCustomerId) throw Object.assign(new Error('Google Ads customer ID is not configured.'), { status: 409 });
  const accessToken = await refreshAccessToken(connection.refreshToken);
  const before = await fetchCampaignState({ accessToken, customerId: connection.googleAdsCustomerId, campaignResourceName: body.campaignResourceName });

  const decision = body.status === 'PAUSED'
    ? await evaluateCampaignPause({ workspaceId, campaignResourceName: body.campaignResourceName, approvedByHuman: body.approvedByHuman })
    : body.approvedByHuman
      ? { allowed: true, requiresApproval: false, reason: 'Human approval supplied.' }
      : { allowed: false, requiresApproval: true, reason: 'Enabling campaigns requires human approval.' };

  if (!decision.allowed) {
    await recordAudit({ workspaceId, actorType: body.approvedByHuman ? 'human' : 'agent', actorId: body.actorId, action: 'google_ads.campaign.status', resourceName: body.campaignResourceName, beforeState: before, reason: decision.reason, result: 'blocked', correlationId });
    res.status(decision.requiresApproval ? 409 : 403).json({ policy: decision, correlationId });
    return;
  }

  await setCampaignStatus({ accessToken, customerId: connection.googleAdsCustomerId, campaignResourceName: body.campaignResourceName, status: body.status });
  const after = await fetchCampaignState({ accessToken, customerId: connection.googleAdsCustomerId, campaignResourceName: body.campaignResourceName });
  await recordAudit({ workspaceId, actorType: body.approvedByHuman ? 'human' : 'agent', actorId: body.actorId, action: 'google_ads.campaign.status', resourceName: body.campaignResourceName, beforeState: before, afterState: after, reason: body.reason ?? decision.reason, result: 'success', correlationId });
  res.json({ ok: true, policy: decision, before, after, correlationId });
});

app.post('/v1/google-ads/budget', requireInternal, requireWorkspace, async (req, res) => {
  const body = z.object({
    campaignBudgetResourceName: z.string().min(1),
    amountMicros: z.string().regex(/^\d+$/),
    approvedByHuman: z.boolean().default(false),
    actorId: z.string().optional(),
    reason: z.string().max(1000).optional(),
  }).parse(req.body);
  const workspaceId = String(res.locals.workspaceId);
  const correlationId = crypto.randomUUID();
  const connection = await requireConnection(workspaceId);
  if (!connection.googleAdsCustomerId) throw Object.assign(new Error('Google Ads customer ID is not configured.'), { status: 409 });
  const accessToken = await refreshAccessToken(connection.refreshToken);
  const before = await fetchCampaignBudgetState({ accessToken, customerId: connection.googleAdsCustomerId, campaignBudgetResourceName: body.campaignBudgetResourceName });
  const currentAmountMicros = BigInt(before?.campaignBudget?.amountMicros ?? '0');
  const decision = await evaluateBudgetChange({ workspaceId, currentAmountMicros, proposedAmountMicros: BigInt(body.amountMicros), approvedByHuman: body.approvedByHuman });

  if (!decision.allowed) {
    await recordAudit({ workspaceId, actorType: body.approvedByHuman ? 'human' : 'agent', actorId: body.actorId, action: 'google_ads.budget.update', resourceName: body.campaignBudgetResourceName, beforeState: before, reason: decision.reason, result: 'blocked', correlationId });
    res.status(decision.requiresApproval ? 409 : 403).json({ policy: decision, correlationId });
    return;
  }

  await setCampaignBudgetMicros({ accessToken, customerId: connection.googleAdsCustomerId, campaignBudgetResourceName: body.campaignBudgetResourceName, amountMicros: body.amountMicros });
  const after = await fetchCampaignBudgetState({ accessToken, customerId: connection.googleAdsCustomerId, campaignBudgetResourceName: body.campaignBudgetResourceName });
  await recordAudit({ workspaceId, actorType: body.approvedByHuman ? 'human' : 'agent', actorId: body.actorId, action: 'google_ads.budget.update', resourceName: body.campaignBudgetResourceName, beforeState: before, afterState: after, reason: body.reason ?? decision.reason, result: 'success', correlationId });
  res.json({ ok: true, policy: decision, before, after, correlationId });
});

app.use((error: unknown, _req: Request, res: Response, _next: NextFunction) => {
  console.error(error);
  if (error instanceof z.ZodError) {
    res.status(400).json({ error: 'validation_error', issues: error.issues });
    return;
  }
  const status = typeof error === 'object' && error && 'status' in error ? Number((error as { status: unknown }).status) : 500;
  res.status(Number.isFinite(status) ? status : 500).json({
    error: status >= 500 ? 'internal_error' : 'request_error',
    message: error instanceof Error ? error.message : 'Unexpected error',
  });
});

app.listen(env.PORT, () => {
  console.log(JSON.stringify({ level: 'info', message: 'xvclean_google_copilot_started', port: env.PORT }));
});
