import type { ResultSetHeader, RowDataPacket } from 'mysql2';
import { getPool } from '../../shared/database/pool';

type CadernetaRow = RowDataPacket & {
  conteudo: Buffer;
  versao_chave: number;
  atualizado_em_ms: number | string;
};

type CarimboRow = RowDataPacket & { atualizado_em_ms: number | string };

export type CadernetaGuardada = {
  conteudo: Buffer;
  versaoChave: number;
  atualizadoEmMs: number;
};

export type ResultadoGravacao =
  | { conflito: false; atualizadoEmMs: number }
  | { conflito: true; atualizadoEmMs: number | null };

const carimboAtual = async (usuarioId: number): Promise<number | null> => {
  const [rows] = await getPool().execute<CarimboRow[]>(
    'SELECT atualizado_em_ms FROM cadernetas_nuvem WHERE usuario_id = ?',
    [usuarioId],
  );
  return rows[0] ? Number(rows[0].atualizado_em_ms) : null;
};

export async function buscar(usuarioId: number): Promise<CadernetaGuardada | null> {
  const [rows] = await getPool().execute<CadernetaRow[]>(
    `SELECT conteudo, versao_chave, atualizado_em_ms
       FROM cadernetas_nuvem WHERE usuario_id = ?`,
    [usuarioId],
  );
  const linha = rows[0];
  if (!linha) return null;
  return {
    conteudo: linha.conteudo,
    versaoChave: Number(linha.versao_chave),
    atualizadoEmMs: Number(linha.atualizado_em_ms),
  };
}

/**
 * Grava só se ninguém mudou a nuvem desde o carimbo que o aparelho conhece.
 *
 * A linha fica travada (`FOR UPDATE`) entre a conferência e a escrita, então
 * dois envios ao mesmo tempo não passam os dois. Sem linha ainda, grava
 * direto: é a primeira caderneta da conta, ou uma que foi apagada.
 *
 * O carimbo novo nunca repete o anterior, mesmo dentro do mesmo milissegundo,
 * porque ele é o que distingue uma versão da outra.
 */
export async function gravarSeBase(
  usuarioId: number,
  dados: { conteudo: Buffer; versaoChave: number; tamanho: number },
  baseMs: number | null,
): Promise<ResultadoGravacao> {
  const conn = await getPool().getConnection();
  try {
    await conn.beginTransaction();
    const [rows] = await conn.execute<CarimboRow[]>(
      'SELECT atualizado_em_ms FROM cadernetas_nuvem WHERE usuario_id = ? FOR UPDATE',
      [usuarioId],
    );
    const atual = rows[0] ? Number(rows[0].atualizado_em_ms) : null;

    if (atual !== null && atual !== baseMs) {
      await conn.rollback();
      return { conflito: true, atualizadoEmMs: atual };
    }

    const novoMs = Math.max(Date.now(), (atual ?? 0) + 1);
    if (atual === null) {
      await conn.execute<ResultSetHeader>(
        `INSERT INTO cadernetas_nuvem
            (usuario_id, conteudo, versao_chave, tamanho, atualizado_em_ms)
         VALUES (?, ?, ?, ?, ?)`,
        [usuarioId, dados.conteudo, dados.versaoChave, dados.tamanho, novoMs],
      );
    } else {
      await conn.execute<ResultSetHeader>(
        `UPDATE cadernetas_nuvem
            SET conteudo = ?, versao_chave = ?, tamanho = ?, atualizado_em_ms = ?
          WHERE usuario_id = ?`,
        [dados.conteudo, dados.versaoChave, dados.tamanho, novoMs, usuarioId],
      );
    }
    await conn.commit();
    return { conflito: false, atualizadoEmMs: novoMs };
  } catch (erro) {
    await conn.rollback();
    // Dois aparelhos da mesma conta mandando a primeira caderneta juntos:
    // sem linha para travar, os dois tentam inserir e um perde, por chave
    // duplicada ou por travamento cruzado. Para quem perdeu é conflito, e o
    // app pergunta. Sem isso o tratador geral diria "E-mail já cadastrado".
    const codigo = (erro as { code?: unknown } | null)?.code;
    if (codigo === 'ER_DUP_ENTRY' || codigo === 'ER_LOCK_DEADLOCK') {
      return { conflito: true, atualizadoEmMs: await carimboAtual(usuarioId) };
    }
    throw erro;
  } finally {
    conn.release();
  }
}

export async function apagar(usuarioId: number): Promise<void> {
  await getPool().execute<ResultSetHeader>(
    'DELETE FROM cadernetas_nuvem WHERE usuario_id = ?',
    [usuarioId],
  );
}
