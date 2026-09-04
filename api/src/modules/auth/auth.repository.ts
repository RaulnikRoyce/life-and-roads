import { createHash } from 'crypto';
import type { ResultSetHeader, RowDataPacket } from 'mysql2';
import { getPool } from '../../shared/database/pool';

export type Usuario = {
  id: number;
  email: string;
  senha: string;
  ativo: number;
};

type UsuarioRow = RowDataPacket & Usuario;
type SessaoRow = RowDataPacket & {
  id: number;
  usuario_id: number;
  token_hash: string;
  expira_em: Date;
  revogada: number;
};

export const hashRefresh = (token: string): string =>
  createHash('sha256').update(token).digest('hex');

export async function buscarPorEmail(email: string): Promise<Usuario | null> {
  const [rows] = await getPool().execute<UsuarioRow[]>(
    'SELECT id, email, senha, ativo FROM usuarios WHERE email = ?',
    [email],
  );
  return rows[0] ?? null;
}

export async function buscarPorId(id: number): Promise<Usuario | null> {
  const [rows] = await getPool().execute<UsuarioRow[]>(
    'SELECT id, email, senha, ativo FROM usuarios WHERE id = ?',
    [id],
  );
  return rows[0] ?? null;
}

export async function salvar(
  email: string,
  senhaCriptografada: string,
): Promise<{ id: number; email: string }> {
  const [result] = await getPool().execute<ResultSetHeader>(
    'INSERT INTO usuarios (email, senha) VALUES (?, ?)',
    [email, senhaCriptografada],
  );
  return { id: result.insertId, email };
}

export async function gravarSessao(
  usuarioId: number,
  tokenHash: string,
  expiraEm: Date,
): Promise<void> {
  const mysql = expiraEm.toISOString().slice(0, 19).replace('T', ' ');
  await getPool().execute(
    'INSERT INTO sessoes (usuario_id, token_hash, expira_em) VALUES (?, ?, ?)',
    [usuarioId, tokenHash, mysql],
  );
}

export async function buscarSessao(tokenHash: string): Promise<SessaoRow | null> {
  const [rows] = await getPool().execute<SessaoRow[]>(
    'SELECT id, usuario_id, token_hash, expira_em, revogada FROM sessoes WHERE token_hash = ?',
    [tokenHash],
  );
  return rows[0] ?? null;
}

export async function rotacionarSessao(
  tokenHash: string,
  usuarioId: number,
  novoTokenHash: string,
  novaExpiracao: Date,
): Promise<'ok' | 'invalida' | 'reutilizada'> {
  const conexao = await getPool().getConnection();
  try {
    await conexao.beginTransaction();
    const [rows] = await conexao.execute<SessaoRow[]>(
      `SELECT id, usuario_id, token_hash, expira_em, revogada
         FROM sessoes WHERE token_hash = ? FOR UPDATE`,
      [tokenHash],
    );
    const sessao = rows[0];
    if (!sessao || sessao.usuario_id !== usuarioId) {
      await conexao.rollback();
      return 'invalida';
    }
    if (Number(sessao.revogada) === 1) {
      await conexao.commit();
      return 'reutilizada';
    }
    if (new Date(sessao.expira_em).getTime() <= Date.now()) {
      await conexao.execute('UPDATE sessoes SET revogada = 1 WHERE id = ?', [sessao.id]);
      await conexao.commit();
      return 'invalida';
    }

    const mysql = novaExpiracao.toISOString().slice(0, 19).replace('T', ' ');
    await conexao.execute('UPDATE sessoes SET revogada = 1 WHERE id = ?', [sessao.id]);
    await conexao.execute(
      'INSERT INTO sessoes (usuario_id, token_hash, expira_em) VALUES (?, ?, ?)',
      [usuarioId, novoTokenHash, mysql],
    );
    await conexao.commit();
    return 'ok';
  } catch (erro) {
    await conexao.rollback();
    throw erro;
  } finally {
    conexao.release();
  }
}

export async function revogarSessao(id: number): Promise<void> {
  await getPool().execute('UPDATE sessoes SET revogada = 1 WHERE id = ?', [id]);
}

export async function revogarTodas(usuarioId: number): Promise<void> {
  await getPool().execute(
    'UPDATE sessoes SET revogada = 1 WHERE usuario_id = ? AND revogada = 0',
    [usuarioId],
  );
}

export async function atualizarSenha(
  id: number,
  senhaCriptografada: string,
): Promise<void> {
  await getPool().execute('UPDATE usuarios SET senha = ? WHERE id = ?', [
    senhaCriptografada,
    id,
  ]);
}

export async function apagarUsuario(id: number): Promise<void> {
  await getPool().execute('DELETE FROM usuarios WHERE id = ?', [id]);
}
