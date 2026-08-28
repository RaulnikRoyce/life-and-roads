import { asyncHandler } from '../../shared/errors';
import { ok } from '../../shared/http/resposta';
import * as manutencaoService from './manutencao.service';
import type { ManutencaoDto } from './manutencao.schema';

export const obter = asyncHandler(async (req, res) => {
  ok(res, await manutencaoService.obter(req.usuario!.id));
});

export const salvar = asyncHandler(async (req, res) => {
  ok(res, await manutencaoService.salvar(req.usuario!.id, req.body as ManutencaoDto));
});
