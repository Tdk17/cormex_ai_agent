import { env } from '../config/env.js';

function normalizeCustomerId(value: string): string {
  return value.replace(/-/g, '').trim();
}

function headers(accessToken: string): Record<string, string> {
  const result: Record<string, string> = {
    authorization: `Bearer ${accessToken}`,
    'developer-token': env.GOOGLE_ADS_DEVELOPER_TOKEN,
    'content-type': 'application/json',
  };
  if (env.GOOGLE_ADS_LOGIN_CUSTOMER_ID) {
    result['login-customer-id'] = normalizeCustomerId(env.GOOGLE_ADS_LOGIN_CUSTOMER_ID);
  }
  return result;
}

async function googleAdsRequest<T>(input: {
  accessToken: string;
  customerId: string;
  path: string;
  body: unknown;
}): Promise<T> {
  const customerId = normalizeCustomerId(input.customerId);
  const response = await fetch(
    `https://googleads.googleapis.com/${env.GOOGLE_ADS_API_VERSION}/customers/${customerId}/${input.path}`,
    {
      method: 'POST',
      headers: headers(input.accessToken),
      body: JSON.stringify(input.body),
    },
  );
  const json = await response.json() as T;
  if (!response.ok) throw new Error(`Google Ads API error (${response.status}): ${JSON.stringify(json)}`);
  return json;
}

async function search<T>(input: {
  accessToken: string;
  customerId: string;
  query: string;
}): Promise<T[]> {
  const result = await googleAdsRequest<Array<{ results?: T[] }>>({
    accessToken: input.accessToken,
    customerId: input.customerId,
    path: 'googleAds:searchStream',
    body: { query: input.query },
  });
  return result.flatMap((batch) => batch.results ?? []);
}

export async function fetchCampaignKpis(input: {
  accessToken: string;
  customerId: string;
  startDate: string;
  endDate: string;
}): Promise<unknown[]> {
  const query = `
    SELECT
      campaign.id,
      campaign.name,
      campaign.resource_name,
      campaign.status,
      campaign.campaign_budget,
      campaign.advertising_channel_type,
      metrics.impressions,
      metrics.clicks,
      metrics.cost_micros,
      metrics.conversions,
      metrics.conversions_value,
      metrics.ctr,
      metrics.average_cpc
    FROM campaign
    WHERE segments.date BETWEEN '${input.startDate}' AND '${input.endDate}'
      AND campaign.status != 'REMOVED'
    ORDER BY metrics.cost_micros DESC`;
  return search({ accessToken: input.accessToken, customerId: input.customerId, query });
}

export async function fetchCampaignState(input: {
  accessToken: string;
  customerId: string;
  campaignResourceName: string;
}): Promise<unknown | null> {
  const escaped = input.campaignResourceName.replace(/'/g, "\\'");
  const rows = await search<unknown>({
    accessToken: input.accessToken,
    customerId: input.customerId,
    query: `SELECT campaign.resource_name, campaign.name, campaign.status, campaign.campaign_budget
            FROM campaign
            WHERE campaign.resource_name = '${escaped}'
            LIMIT 1`,
  });
  return rows[0] ?? null;
}

export async function fetchCampaignBudgetState(input: {
  accessToken: string;
  customerId: string;
  campaignBudgetResourceName: string;
}): Promise<{ campaignBudget?: { resourceName?: string; amountMicros?: string } } | null> {
  const escaped = input.campaignBudgetResourceName.replace(/'/g, "\\'");
  const rows = await search<{ campaignBudget?: { resourceName?: string; amountMicros?: string } }>({
    accessToken: input.accessToken,
    customerId: input.customerId,
    query: `SELECT campaign_budget.resource_name, campaign_budget.amount_micros
            FROM campaign_budget
            WHERE campaign_budget.resource_name = '${escaped}'
            LIMIT 1`,
  });
  return rows[0] ?? null;
}

export async function setCampaignStatus(input: {
  accessToken: string;
  customerId: string;
  campaignResourceName: string;
  status: 'ENABLED' | 'PAUSED';
}): Promise<unknown> {
  return googleAdsRequest({
    accessToken: input.accessToken,
    customerId: input.customerId,
    path: 'campaigns:mutate',
    body: {
      operations: [{
        updateMask: 'status',
        update: {
          resourceName: input.campaignResourceName,
          status: input.status,
        },
      }],
      responseContentType: 'MUTABLE_RESOURCE',
    },
  });
}

export async function setCampaignBudgetMicros(input: {
  accessToken: string;
  customerId: string;
  campaignBudgetResourceName: string;
  amountMicros: string;
}): Promise<unknown> {
  return googleAdsRequest({
    accessToken: input.accessToken,
    customerId: input.customerId,
    path: 'campaignBudgets:mutate',
    body: {
      operations: [{
        updateMask: 'amount_micros',
        update: {
          resourceName: input.campaignBudgetResourceName,
          amountMicros: input.amountMicros,
        },
      }],
      responseContentType: 'MUTABLE_RESOURCE',
    },
  });
}
