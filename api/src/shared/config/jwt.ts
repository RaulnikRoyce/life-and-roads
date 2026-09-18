export const ACCESS_SEGUNDOS = 15 * 60;
export const REFRESH_SEGUNDOS = 30 * 24 * 60 * 60;
export const REFRESH_MS = REFRESH_SEGUNDOS * 1000;
/**
 * Janela em que um refresh já rotacionado ainda é aceito.
 * Cobre as abas do app renovando ao mesmo tempo com o mesmo token.
 * Fora dela, reuso de token rotacionado revoga a conta inteira.
 */
export const REFRESH_TOLERANCIA_SEGUNDOS = 15;
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
