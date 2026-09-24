import { asyncHandler } from '../../shared/errors';
import { ok } from '../../shared/http/resposta';
import * as cadernetaService from './caderneta.service';
import type { SalvarCadernetaDto } from './caderneta.schema';

export const obter = asyncHandler(async (req, res) => {
  ok(res, await cadernetaService.obter(req.usuario!.id));
});

export const salvar = asyncHandler(async (req, res) => {
  ok(res, await cadernetaService.salvar(req.usuario!.id, req.body as SalvarCadernetaDto));
});

export const apagar = asyncHandler(async (req, res) => {
  await cadernetaService.apagar(req.usuario!.id);
  res.status(204).end();
});
