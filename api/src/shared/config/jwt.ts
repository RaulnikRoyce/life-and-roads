export const ACCESS_SEGUNDOS = 15 * 60;
export const REFRESH_SEGUNDOS = 30 * 24 * 60 * 60;
export const REFRESH_MS = REFRESH_SEGUNDOS * 1000;

export const getJwtSecret = (): string => {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error('JWT_SECRET não configurado.');
  }
  return secret;
};
