export type AppEnv = 'development' | 'staging' | 'production';

export function appEnv(): AppEnv {
  const bruto = String(process.env.APP_ENV || process.env.NODE_ENV || 'development')
    .trim()
    .toLowerCase();
  if (bruto === 'staging') return 'staging';
  if (bruto === 'production') return 'production';
  return 'development';
}
