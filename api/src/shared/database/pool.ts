import dns from 'dns';
import mysql from 'mysql2/promise';

dns.setDefaultResultOrder('ipv4first');

let pool: mysql.Pool | null = null;

export function getPool(): mysql.Pool {
  if (pool) return pool;
  pool = mysql.createPool({
    host: process.env.DB_HOST || '',
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: Number(process.env.DB_PORT) || 3306,
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
