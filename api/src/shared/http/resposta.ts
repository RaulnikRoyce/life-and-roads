import type { Response } from 'express';

export const ok = (res: Response, dados: unknown, status = 200): Response =>
  res.status(status).json(dados);

export const criado = (
  res: Response,
  mensagem: string,
  extra: Record<string, unknown> = {},
): Response => res.status(201).json({ mensagem, ...extra });
