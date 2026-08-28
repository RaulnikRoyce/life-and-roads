import { AppError } from '../../shared/errors';
import * as manutencaoRepository from './manutencao.repository';
import type { ManutencaoDto } from './manutencao.schema';

export const obter = async (usuarioId: number): Promise<ManutencaoDto> => {
  const manutencao = await manutencaoRepository.buscarPorUsuario(usuarioId);
  if (!manutencao) {
    throw new AppError(404, 'Nenhuma manutenção ainda');
  }
  return manutencao;
};

export const salvar = (usuarioId: number, dados: ManutencaoDto) =>
  manutencaoRepository.salvar(usuarioId, dados);
