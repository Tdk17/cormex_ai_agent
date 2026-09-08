import crypto from 'node:crypto';
import { tokenEncryptionKey } from '../config/env.js';

const ALGORITHM = 'aes-256-gcm';
const IV_BYTES = 12;

export function encryptSecret(value: string): string {
  const iv = crypto.randomBytes(IV_BYTES);
  const cipher = crypto.createCipheriv(ALGORITHM, tokenEncryptionKey, iv);
  const ciphertext = Buffer.concat([cipher.update(value, 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return Buffer.concat([iv, tag, ciphertext]).toString('base64');
}

export function decryptSecret(payload: string): string {
  const packed = Buffer.from(payload, 'base64');
  if (packed.length <= IV_BYTES + 16) throw new Error('Invalid encrypted secret payload.');

  const iv = packed.subarray(0, IV_BYTES);
  const tag = packed.subarray(IV_BYTES, IV_BYTES + 16);
  const ciphertext = packed.subarray(IV_BYTES + 16);

  const decipher = crypto.createDecipheriv(ALGORITHM, tokenEncryptionKey, iv);
  decipher.setAuthTag(tag);
  return Buffer.concat([decipher.update(ciphertext), decipher.final()]).toString('utf8');
}
