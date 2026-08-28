import { asyncHandler } from '../../shared/errors';
import { ok } from '../../shared/http/resposta';
import * as localizacaoService from './localizacao.service';
import type { LocalizacaoDto } from './localizacao.schema';

export const obter = asyncHandler(async (req, res) => {
  ok(res, await localizacaoService.obter(req.usuario!.id));
});

export const salvar = asyncHandler(async (req, res) => {
  ok(res, await localizacaoService.salvar(req.usuario!.id, req.body as LocalizacaoDto));
});
