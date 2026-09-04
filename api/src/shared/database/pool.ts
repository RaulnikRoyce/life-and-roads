import dns from 'dns';
import mysql from 'mysql2/promise';

dns.setDefaultResultOrder('ipv4first');

let pool: mysql.Pool | null = null;

export function sslBanco(): mysql.PoolOptions['ssl'] {
  const caBase64 = String(process.env.DB_SSL_CA_BASE64 || '').trim();
  if (!caBase64) return undefined;

  const ca = Buffer.from(caBase64, 'base64').toString('utf8');
  if (!ca.includes('-----BEGIN CERTIFICATE-----')) {
    throw new Error('DB_SSL_CA_BASE64 não contém um certificado PEM válido.');
  }
  return { ca, rejectUnauthorized: true };
}

export function getPool(): mysql.Pool {
  if (pool) return pool;
  pool = mysql.createPool({
    host: process.env.DB_HOST || '',
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: Number(process.env.DB_PORT) || 3306,
    ssl: sslBanco(),
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    connectTimeout: 4000,
  });
  return pool;
}

export async function pingBanco(): Promise<void> {
  const conn = await getPool().getConnection();
  try {
    await conn.ping();
  } finally {
    conn.release();
  }
}

export async function fecharPool(): Promise<void> {
  if (!pool) return;
  await pool.end();
  pool = null;
}
