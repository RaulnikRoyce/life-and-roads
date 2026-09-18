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
    // DATETIME é gravado em UTC (expira_em); ler em UTC evita depender do
    // fuso do processo.
    timezone: 'Z',
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

/** Versão do servidor (MySQL 8.0.x, 8.4.x, MariaDB…). Vai para o log de boot. */
export async function versaoBanco(): Promise<string> {
  const [rows] = await getPool().query<import('mysql2').RowDataPacket[]>(
    'SELECT VERSION() AS versao',
  );
  return String(rows[0]?.versao ?? 'desconhecida');
}

export async function fecharPool(): Promise<void> {
  if (!pool) return;
  await pool.end();
  pool = null;
}
