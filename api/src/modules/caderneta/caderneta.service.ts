import { AppError } from '../../shared/errors';
import { logger } from '../../shared/http/logger';
import {
  VERSAO_CHAVE_ATUAL,
  chaveDaCaderneta,
  cifrar,
  decifrar,
} from '../../shared/cripto/caderneta';
import * as repo from './caderneta.repository';
import type { ConteudoCaderneta, SalvarCadernetaDto } from './caderneta.schema';

export type CadernetaLida = { conteudo: ConteudoCaderneta; atualizadoEm: string };

const iso = (ms: number): string => new Date(ms).toISOString();

/**
 * Sem a chave, a caderneta na nuvem fica indisponível e o resto da API segue
 * normal, como a recuperação de senha sem a chave do Resend.
 */
const chaveOuIndisponivel = (): Buffer => {
  const chave = chaveDaCaderneta();
  if (!chave) throw new AppError(503, 'A caderneta na nuvem está indisponível agora.');
  return chave;
};

export const obter = async (usuarioId: number): Promise<CadernetaLida> => {
  const chave = chaveOuIndisponivel();
  const guardada = await repo.buscar(usuarioId);
  if (!guardada) throw new AppError(404, 'Nenhuma caderneta na nuvem ainda');

  let texto: string;
  try {
    if (guardada.versaoChave !== VERSAO_CHAVE_ATUAL) {
      throw new Error(`versão de chave ${guardada.versaoChave} sem chave configurada`);
    }
    texto = decifrar(guardada.conteudo, chave, usuarioId);
  } catch (erro) {
    // Chave trocada ou conteúdo mexido no banco. Nunca devolve lixo.
    logger.error('Caderneta na nuvem não abriu', {
      usuarioId,
      detalhe: erro instanceof Error ? erro.message : 'erro',
    });
    throw new AppError(500, 'Não foi possível abrir a caderneta guardada.');
  }
  return {
    conteudo: JSON.parse(texto) as ConteudoCaderneta,
    atualizadoEm: iso(guardada.atualizadoEmMs),
  };
};

export const salvar = async (
  usuarioId: number,
  dados: SalvarCadernetaDto,
): Promise<{ atualizadoEm: string }> => {
  const chave = chaveOuIndisponivel();
  const texto = JSON.stringify(dados.conteudo);
  const conteudo = cifrar(texto, chave, usuarioId);
  const baseMs = dados.baseAtualizadoEm === null ? null : Date.parse(dados.baseAtualizadoEm);

  const resultado = await repo.gravarSeBase(
    usuarioId,
    { conteudo, versaoChave: VERSAO_CHAVE_ATUAL, tamanho: Buffer.byteLength(texto) },
    baseMs,
  );
  if (resultado.conflito) {
    throw new AppError(409, 'A caderneta na nuvem mudou em outro aparelho.', {
      atualizadoEm: resultado.atualizadoEmMs === null ? null : iso(resultado.atualizadoEmMs),
    });
  }
  return { atualizadoEm: iso(resultado.atualizadoEmMs) };
};

/** O interruptor desligado. Não precisa da chave: apagar não abre nada. */
export const apagar = (usuarioId: number): Promise<void> => repo.apagar(usuarioId);
