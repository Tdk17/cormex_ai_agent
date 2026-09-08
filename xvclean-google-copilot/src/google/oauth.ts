import crypto from 'node:crypto';
import { env } from '../config/env.js';

const SCOPES = [
  'openid',
  'email',
  'https://www.googleapis.com/auth/adwords',
  'https://www.googleapis.com/auth/analytics.readonly',
  'https://www.googleapis.com/auth/webmasters.readonly',
];

type OAuthState = { workspaceId: string; nonce: string; issuedAt: number };

function sign(value: string): string {
  return crypto.createHmac('sha256', env.STATE_SIGNING_SECRET).update(value).digest('base64url');
}

export function createOAuthState(workspaceId: string): string {
  const payload: OAuthState = {
    workspaceId,
    nonce: crypto.randomUUID(),
    issuedAt: Date.now(),
  };
  const encoded = Buffer.from(JSON.stringify(payload)).toString('base64url');
  return `${encoded}.${sign(encoded)}`;
}

export function verifyOAuthState(state: string): OAuthState {
  const [encoded, signature] = state.split('.');
  if (!encoded || !signature) throw new Error('Invalid OAuth state.');
  const expected = sign(encoded);
  if (!crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected))) {
    throw new Error('Invalid OAuth state signature.');
  }
  const payload = JSON.parse(Buffer.from(encoded, 'base64url').toString('utf8')) as OAuthState;
  if (Date.now() - payload.issuedAt > 10 * 60 * 1000) throw new Error('OAuth state expired.');
  return payload;
}

export function buildGoogleAuthorizationUrl(workspaceId: string): string {
  const params = new URLSearchParams({
    client_id: env.GOOGLE_CLIENT_ID,
    redirect_uri: env.GOOGLE_REDIRECT_URI,
    response_type: 'code',
    access_type: 'offline',
    include_granted_scopes: 'true',
    prompt: 'consent',
    scope: SCOPES.join(' '),
    state: createOAuthState(workspaceId),
  });
  return `https://accounts.google.com/o/oauth2/v2/auth?${params.toString()}`;
}

export async function exchangeAuthorizationCode(code: string): Promise<{
  accessToken: string;
  refreshToken: string;
  scope: string[];
}> {
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      code,
      client_id: env.GOOGLE_CLIENT_ID,
      client_secret: env.GOOGLE_CLIENT_SECRET,
      redirect_uri: env.GOOGLE_REDIRECT_URI,
      grant_type: 'authorization_code',
    }),
  });
  const json = await response.json() as Record<string, unknown>;
  if (!response.ok) throw new Error(`Google OAuth token exchange failed: ${JSON.stringify(json)}`);
  const refreshToken = String(json.refresh_token ?? '');
  if (!refreshToken) throw new Error('Google did not return a refresh token. Revoke the app grant and authorize again.');
  return {
    accessToken: String(json.access_token),
    refreshToken,
    scope: String(json.scope ?? '').split(' ').filter(Boolean),
  };
}

export async function refreshAccessToken(refreshToken: string): Promise<string> {
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      refresh_token: refreshToken,
      client_id: env.GOOGLE_CLIENT_ID,
      client_secret: env.GOOGLE_CLIENT_SECRET,
      grant_type: 'refresh_token',
    }),
  });
  const json = await response.json() as Record<string, unknown>;
  if (!response.ok) throw new Error(`Google OAuth refresh failed: ${JSON.stringify(json)}`);
  return String(json.access_token);
}

export async function fetchGoogleEmail(accessToken: string): Promise<string | null> {
  const response = await fetch('https://openidconnect.googleapis.com/v1/userinfo', {
    headers: { authorization: `Bearer ${accessToken}` },
  });
  if (!response.ok) return null;
  const json = await response.json() as { email?: string };
  return json.email ?? null;
}
