import { AppError } from '../../shared/errors';
import * as fichaRepository from './ficha.repository';
import type { FichaDto } from './ficha.schema';
import type { FichaLida } from './ficha.repository';

export const obter = async (usuarioId: number): Promise<FichaLida> => {
  const ficha = await fichaRepository.buscarPorUsuario(usuarioId);
  if (!ficha) {
    throw new AppError(404, 'Nenhuma ficha ainda');
  }
  return ficha;
};

export const salvar = (usuarioId: number, dados: FichaDto) =>
  fichaRepository.salvar(usuarioId, dados);
