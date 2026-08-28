import { asyncHandler } from '../../shared/errors';
import { ok } from '../../shared/http/resposta';
import * as fichaService from './ficha.service';
import type { FichaDto } from './ficha.schema';

export const obter = asyncHandler(async (req, res) => {
  ok(res, await fichaService.obter(req.usuario!.id));
});

export const salvar = asyncHandler(async (req, res) => {
  ok(res, await fichaService.salvar(req.usuario!.id, req.body as FichaDto), 200);
});
