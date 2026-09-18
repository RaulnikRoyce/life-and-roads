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
  rotacionada_em: Date | null;
  segundos_rotacao: number | null;
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
    `SELECT id, usuario_id, token_hash, expira_em, revogada, rotacionada_em,
            NULL AS segundos_rotacao
       FROM sessoes WHERE token_hash = ?`,
    [tokenHash],
  );
  return rows[0] ?? null;
}

/**
 * Troca um refresh por outro dentro de uma transação.
 *
 * - `ok`: rotacionou (ou o token foi rotacionado há poucos segundos e este é
 *   um retry concorrente; nesse caso só emite outra sessão).
 * - `reutilizada`: token já trocado fora da janela. Sinal de roubo; o
 *   serviço revoga a conta.
 * - `invalida`: não existe, é de outro usuário, venceu, ou foi revogado por
 *   sair / troca de senha (aparelho atrasado, sem punição).
 */
export async function rotacionarSessao(
  tokenHash: string,
  usuarioId: number,
  novoTokenHash: string,
  novaExpiracao: Date,
  toleranciaSegundos: number,
): Promise<'ok' | 'invalida' | 'reutilizada'> {
  const conexao = await getPool().getConnection();
  try {
    await conexao.beginTransaction();
    const [rows] = await conexao.execute<SessaoRow[]>(
      `SELECT id, usuario_id, token_hash, expira_em, revogada, rotacionada_em,
              TIMESTAMPDIFF(SECOND, rotacionada_em, NOW()) AS segundos_rotacao
         FROM sessoes WHERE token_hash = ? FOR UPDATE`,
      [tokenHash],
    );
    const sessao = rows[0];
    if (!sessao || sessao.usuario_id !== usuarioId) {
      await conexao.rollback();
      return 'invalida';
    }

    const mysql = novaExpiracao.toISOString().slice(0, 19).replace('T', ' ');
    const inserirNova = () => conexao.execute(
      'INSERT INTO sessoes (usuario_id, token_hash, expira_em) VALUES (?, ?, ?)',
      [usuarioId, novoTokenHash, mysql],
    );

    if (Number(sessao.revogada) === 1) {
      const rotacionada = sessao.rotacionada_em != null;
      const segundos = Number(sessao.segundos_rotacao);
      if (rotacionada && Number.isFinite(segundos) && segundos <= toleranciaSegundos) {
        await inserirNova();
        await conexao.commit();
        return 'ok';
      }
      await conexao.commit();
      return rotacionada ? 'reutilizada' : 'invalida';
    }

    if (new Date(sessao.expira_em).getTime() <= Date.now()) {
      await conexao.execute('UPDATE sessoes SET revogada = 1 WHERE id = ?', [sessao.id]);
      await conexao.commit();
      return 'invalida';
    }

    await conexao.execute(
      'UPDATE sessoes SET revogada = 1, rotacionada_em = NOW() WHERE id = ?',
      [sessao.id],
    );
    await inserirNova();
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
  // Zera rotacionada_em: depois de sair, senha ou roubo detectado, nenhum
  // token antigo desta conta entra na janela de tolerância.
  await getPool().execute(
    'UPDATE sessoes SET revogada = 1, rotacionada_em = NULL WHERE usuario_id = ?',
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
