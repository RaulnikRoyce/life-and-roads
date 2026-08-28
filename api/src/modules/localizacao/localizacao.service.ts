import { AppError } from '../../shared/errors';
import * as localizacaoRepository from './localizacao.repository';
import type { LocalizacaoDto } from './localizacao.schema';

export const obter = async (usuarioId: number): Promise<LocalizacaoDto> => {
  const ponto = await localizacaoRepository.buscarPorUsuario(usuarioId);
  if (!ponto) {
    throw new AppError(404, 'Nenhum ponto ainda');
  }
  return ponto;
};

export const salvar = (usuarioId: number, dados: LocalizacaoDto) =>
  localizacaoRepository.salvar(usuarioId, dados);
