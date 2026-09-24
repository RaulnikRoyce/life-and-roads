import { createHash } from 'crypto';
import type { ResultSetHeader, RowDataPacket } from 'mysql2';
import { getPool } from '../../shared/database/pool';

export type Usuario = {
  id: number;
  email: string;
  senha: string;
  ativo: number;
  /** Data do texto dos termos aceito, ou null (ADR 0038). */
  termos_versao: string | null;
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
    'SELECT id, email, senha, ativo, termos_versao FROM usuarios WHERE email = ?',
    [email],
  );
  return rows[0] ?? null;
}

export async function buscarPorId(id: number): Promise<Usuario | null> {
  const [rows] = await getPool().execute<UsuarioRow[]>(
    'SELECT id, email, senha, ativo, termos_versao FROM usuarios WHERE id = ?',
    [id],
  );
  return rows[0] ?? null;
}

export async function salvar(
  email: string,
  senhaCriptografada: string,
  termosVersao: string | null = null,
): Promise<{ id: number; email: string }> {
  // Sem versão, como no APK antigo, a data do aceite também fica nula.
  const [result] = await getPool().execute<ResultSetHeader>(
    `INSERT INTO usuarios (email, senha, termos_versao, termos_aceitos_em)
     VALUES (?, ?, ?, CASE WHEN ? IS NULL THEN NULL ELSE UTC_TIMESTAMP() END)`,
    [email, senhaCriptografada, termosVersao, termosVersao],
  );
  return { id: result.insertId, email };
}

/** Registra o aceite de quem já tem conta. Devolve se a conta existia. */
export async function registrarAceiteTermos(
  usuarioId: number,
  versao: string,
): Promise<boolean> {
  const [result] = await getPool().execute<ResultSetHeader>(
    'UPDATE usuarios SET termos_versao = ?, termos_aceitos_em = UTC_TIMESTAMP() WHERE id = ?',
    [versao, usuarioId],
  );
  return result.affectedRows > 0;
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

/**
 * Apaga sessões vencidas. As revogadas dentro do prazo ficam: são elas que
 * denunciam reuso de refresh. `expira_em` é gravado em UTC, daí UTC_TIMESTAMP().
 */
export async function apagarSessoesVencidas(): Promise<number> {
  const [r] = await getPool().execute<ResultSetHeader>(
    'DELETE FROM sessoes WHERE expira_em < UTC_TIMESTAMP()',
  );
  return r.affectedRows;
}

// Recuperação de senha por código. Só o HMAC do código vai para o banco.

export type Recuperacao = {
  id: number;
  usuario_id: number;
  codigo_hash: string;
  tentativas: number;
};

type RecuperacaoRow = RowDataPacket & Recuperacao;

const paraMysql = (data: Date): string =>
  data.toISOString().slice(0, 19).replace('T', ' ');

/**
 * Grava um código novo e marca os anteriores da conta como usados. Eles
 * ficam na tabela porque a contagem por hora precisa do histórico.
 *
 * A contagem roda dentro da transação, depois de travar a linha do usuário
 * com FOR UPDATE. Pedidos simultâneos para a mesma conta entram um de cada
 * vez, e cada um conta já vendo o que o anterior gravou.
 *
 * - `criado`: gravou.
 * - `limite`: a conta já tem `maximoPorHora` códigos criados na última hora.
 * - `sem_conta`: usuário sumiu ou foi desativado entre a busca e a gravação.
 */
export async function criarCodigoRecuperacao(
  usuarioId: number,
  codigoHash: string,
  expiraEm: Date,
  maximoPorHora: number,
): Promise<'criado' | 'limite' | 'sem_conta'> {
  const conexao = await getPool().getConnection();
  try {
    await conexao.beginTransaction();
    const [donos] = await conexao.execute<RowDataPacket[]>(
      'SELECT id FROM usuarios WHERE id = ? AND ativo = 1 FOR UPDATE',
      [usuarioId],
    );
    if (donos.length === 0) {
      await conexao.rollback();
      return 'sem_conta';
    }
    const [contagem] = await conexao.execute<RowDataPacket[]>(
      `SELECT COUNT(*) AS total FROM recuperacoes_senha
        WHERE usuario_id = ? AND criado_em >= NOW() - INTERVAL 1 HOUR`,
      [usuarioId],
    );
    if (Number(contagem[0]?.total ?? 0) >= maximoPorHora) {
      await conexao.rollback();
      return 'limite';
    }
    await conexao.execute(
      `UPDATE recuperacoes_senha SET usada_em = UTC_TIMESTAMP()
        WHERE usuario_id = ? AND usada_em IS NULL`,
      [usuarioId],
    );
    await conexao.execute(
      `INSERT INTO recuperacoes_senha (usuario_id, codigo_hash, expira_em)
       VALUES (?, ?, ?)`,
      [usuarioId, codigoHash, paraMysql(expiraEm)],
    );
    await conexao.commit();
    return 'criado';
  } catch (erro) {
    await conexao.rollback();
    throw erro;
  } finally {
    conexao.release();
  }
}

/** Código mais recente da conta ainda não usado e dentro do prazo. */
export async function buscarCodigoAtivo(usuarioId: number): Promise<Recuperacao | null> {
  const [rows] = await getPool().execute<RecuperacaoRow[]>(
    `SELECT id, usuario_id, codigo_hash, tentativas FROM recuperacoes_senha
      WHERE usuario_id = ? AND usada_em IS NULL AND expira_em > UTC_TIMESTAMP()
      ORDER BY id DESC LIMIT 1`,
    [usuarioId],
  );
  return rows[0] ?? null;
}

/**
 * Gasta uma tentativa antes de conferir o código, no próprio UPDATE, para
 * pedidos simultâneos não passarem do limite. `false` quando esgotou.
 */
export async function consumirTentativa(id: number, maximo: number): Promise<boolean> {
  const [r] = await getPool().execute<ResultSetHeader>(
    `UPDATE recuperacoes_senha SET tentativas = tentativas + 1
      WHERE id = ? AND usada_em IS NULL AND tentativas < ?`,
    [id, maximo],
  );
  return r.affectedRows === 1;
}

/** Uso único: `false` se outro pedido já marcou este código. */
export async function marcarCodigoUsado(id: number): Promise<boolean> {
  const [r] = await getPool().execute<ResultSetHeader>(
    `UPDATE recuperacoes_senha SET usada_em = UTC_TIMESTAMP()
      WHERE id = ? AND usada_em IS NULL`,
    [id],
  );
  return r.affectedRows === 1;
}

/** Apaga códigos vencidos há mais de um dia. Os da última hora ficam para a contagem. */
export async function apagarRecuperacoesVencidas(): Promise<number> {
  const [r] = await getPool().execute<ResultSetHeader>(
    'DELETE FROM recuperacoes_senha WHERE expira_em < UTC_TIMESTAMP() - INTERVAL 1 DAY',
  );
  return r.affectedRows;
}

