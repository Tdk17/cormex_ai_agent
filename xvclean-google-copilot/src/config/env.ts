import 'dotenv/config';
import { z } from 'zod';

const schema = z.object({
  PORT: z.coerce.number().int().positive().default(8787),
  APP_ORIGIN: z.string().url(),
  DATABASE_URL: z.string().min(1),
  INTERNAL_API_KEY: z.string().min(24),
  STATE_SIGNING_SECRET: z.string().min(24),
  TOKEN_ENCRYPTION_KEY_BASE64: z.string().min(40),
  GOOGLE_CLIENT_ID: z.string().min(1),
  GOOGLE_CLIENT_SECRET: z.string().min(1),
  GOOGLE_REDIRECT_URI: z.string().url(),
  GOOGLE_ADS_DEVELOPER_TOKEN: z.string().min(1),
  GOOGLE_ADS_LOGIN_CUSTOMER_ID: z.string().optional(),
  GOOGLE_ADS_API_VERSION: z.string().regex(/^v\d+$/).default('v22'),
});

export const env = schema.parse(process.env);

const encryptionKey = Buffer.from(env.TOKEN_ENCRYPTION_KEY_BASE64, 'base64');
if (encryptionKey.length !== 32) {
  throw new Error('TOKEN_ENCRYPTION_KEY_BASE64 must decode to exactly 32 bytes.');
}

export const tokenEncryptionKey = encryptionKey;
