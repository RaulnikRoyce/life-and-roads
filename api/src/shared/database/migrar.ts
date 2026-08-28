import fs from 'fs';
import path from 'path';
import { getPool } from './pool';
import { logger } from '../http/logger';

/** Aplica arquivos `.sql` em `database/migrations/` uma vez cada. */
export async function migrar(): Promise<void> {
  const pool = getPool();
  await pool.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      id VARCHAR(64) NOT NULL PRIMARY KEY,
      aplicada_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);

  const pasta = path.join(process.cwd(), 'database', 'migrations');
  if (!fs.existsSync(pasta)) return;

  const arquivos = fs.readdirSync(pasta)
    .filter((f) => f.endsWith('.sql'))
    .sort();

  for (const arquivo of arquivos) {
    const [ja] = await pool.query(
      'SELECT id FROM schema_migrations WHERE id = ?',
      [arquivo],
    );
    if (Array.isArray(ja) && ja.length > 0) continue;

    const sql = fs.readFileSync(path.join(pasta, arquivo), 'utf8');
    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();
      await conn.query(sql);
      await conn.query(
        'INSERT INTO schema_migrations (id) VALUES (?)',
        [arquivo],
      );
      await conn.commit();
      logger.info('migration', { arquivo });
    } catch (erro) {
      await conn.rollback();
      throw erro;
    } finally {
      conn.release();
    }
  }
}
