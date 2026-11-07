import type { PoolConnection } from 'mysql2/promise';
import type { RowDataPacket } from 'mysql2';
import { getPool } from './pool';
import { AppError } from '../errors';

/** undefined preserva o protocolo legado; null exige que ainda nao exista. */
export function lerBaseVersao(valor: string | undefined): number | null | undefined {
  if (valor === undefined) return undefined;
  if (valor === 'null') return null;
  if (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/.test(valor)) throw new AppError(400, 'Versão de sincronização inválida.');
  const ms = Date.parse(valor);
  if (!Number.isFinite(ms) || new Date(ms).toISOString() !== valor) throw new AppError(400, 'Versão de sincronização inválida.');
  return ms;
}
export async function gravarVersionado(
  tabela: 'fichas' | 'manutencoes', usuarioId: number, base: number | null | undefined,
  escrever: (conn: PoolConnection) => Promise<unknown>,
): Promise<string> {
  const conn = await getPool().getConnection();
  try {
    await conn.beginTransaction();
    // A conta existe mesmo na primeira gravacao.
    const [donos] = await conn.execute<RowDataPacket[]>('SELECT id FROM usuarios WHERE id = ? FOR UPDATE', [usuarioId]);
    if (!donos.length) throw new AppError(404, 'Conta não encontrada.');
    const [rows] = await conn.execute<RowDataPacket[]>(`SELECT COALESCE(atualizado_em_ms, UNIX_TIMESTAMP(atualizado_em) * 1000) AS atualizado_em_ms FROM ${tabela} WHERE usuario_id = ?`, [usuarioId]);
    const atual = rows[0] ? Number(rows[0].atualizado_em_ms) : null;
    if (base !== undefined && base !== atual) throw new AppError(409, 'Os dados mudaram em outro aparelho.', {atualizadoEm: atual === null ? null : new Date(atual).toISOString()});
    const novo = Math.max(Date.now(), (atual ?? 0) + 1);
    await escrever(conn);
    await conn.execute(`UPDATE ${tabela} SET atualizado_em_ms = ? WHERE usuario_id = ?`, [novo, usuarioId]);
    await conn.commit();
    return new Date(novo).toISOString();
  } catch (erro) {
    await conn.rollback(); throw erro;
  } finally { conn.release(); }
}
