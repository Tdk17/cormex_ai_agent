import { db } from '../infra/db.js';
import { decryptSecret, encryptSecret } from '../security/tokenCipher.js';

export type GoogleConnection = {
  workspaceId: string;
  googleEmail: string | null;
  refreshToken: string;
  scopes: string[];
  googleAdsCustomerId: string | null;
  ga4PropertyId: string | null;
  searchConsoleSiteUrl: string | null;
};

export async function upsertGoogleConnection(input: {
  workspaceId: string;
  googleEmail?: string | null;
  refreshToken: string;
  scopes: string[];
}): Promise<void> {
  await db.query(
    `INSERT INTO xv_google_connections
      (workspace_id, google_email, refresh_token_encrypted, scopes)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (workspace_id) DO UPDATE SET
       google_email = EXCLUDED.google_email,
       refresh_token_encrypted = EXCLUDED.refresh_token_encrypted,
       scopes = EXCLUDED.scopes,
       updated_at = NOW()`,
    [input.workspaceId, input.googleEmail ?? null, encryptSecret(input.refreshToken), input.scopes],
  );
}

export async function getGoogleConnection(workspaceId: string): Promise<GoogleConnection | null> {
  const result = await db.query(
    `SELECT workspace_id, google_email, refresh_token_encrypted, scopes,
            google_ads_customer_id, ga4_property_id, search_console_site_url
       FROM xv_google_connections
      WHERE workspace_id = $1`,
    [workspaceId],
  );
  const row = result.rows[0];
  if (!row) return null;
  return {
    workspaceId: row.workspace_id,
    googleEmail: row.google_email,
    refreshToken: decryptSecret(row.refresh_token_encrypted),
    scopes: row.scopes ?? [],
    googleAdsCustomerId: row.google_ads_customer_id,
    ga4PropertyId: row.ga4_property_id,
    searchConsoleSiteUrl: row.search_console_site_url,
  };
}

export async function updateGooglePropertyIds(input: {
  workspaceId: string;
  googleAdsCustomerId?: string | null;
  ga4PropertyId?: string | null;
  searchConsoleSiteUrl?: string | null;
}): Promise<void> {
  await db.query(
    `UPDATE xv_google_connections SET
       google_ads_customer_id = COALESCE($2, google_ads_customer_id),
       ga4_property_id = COALESCE($3, ga4_property_id),
       search_console_site_url = COALESCE($4, search_console_site_url),
       updated_at = NOW()
     WHERE workspace_id = $1`,
    [input.workspaceId, input.googleAdsCustomerId ?? null, input.ga4PropertyId ?? null, input.searchConsoleSiteUrl ?? null],
  );
}
