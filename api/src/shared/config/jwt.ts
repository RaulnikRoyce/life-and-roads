export const ACCESS_SEGUNDOS = 15 * 60;
export const REFRESH_SEGUNDOS = 30 * 24 * 60 * 60;
export const REFRESH_MS = REFRESH_SEGUNDOS * 1000;
export const JWT_ALGORITHM = 'HS256' as const;
export const JWT_ISSUER = 'life-and-roads-api';
export const JWT_AUDIENCE = 'life-and-roads-app';

export const getJwtSecret = (): string => {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error('JWT_SECRET não configurado.');
  }
  if (Buffer.byteLength(secret, 'utf8') < 32) {
    throw new Error('JWT_SECRET deve ter pelo menos 32 bytes.');
  }
  return secret;
};
