import type { Request, Response, NextFunction } from 'express';
import { logger } from './logger';
import { AppError } from '../errors';
import { appEnv } from '../config/ambiente';

export const manipularErros = (
  err: unknown,
  req: Request,
  res: Response,
  next: NextFunction,
): void => {
  if (res.headersSent) {
    next(err);
    return;
  }

  if (err instanceof AppError) {
    const corpo: { erro: string; detalhes?: unknown } = { erro: err.message };
    if (err.detalhes) corpo.detalhes = err.detalhes;
    res.status(err.status).json(corpo);
    return;
  }

  const codigo = err && typeof err === 'object' && 'code' in err
    ? String((err as { code: unknown }).code)
    : '';
  if (codigo === 'ER_DUP_ENTRY') {
    res.status(409).json({ erro: 'E-mail já cadastrado.' });
    return;
  }

  const detalhe = err instanceof Error ? err.message : 'erro';
  logger.error('Erro não tratado', {
    rota: req.originalUrl,
    metodo: req.method,
    request_id: req.requestId,
    env: appEnv(),
    detalhe,
  });

  res.status(500).json({ erro: 'Erro interno do servidor' });
};

export const rotaNaoEncontrada = (req: Request, res: Response): void => {
  res.status(404).json({ erro: 'Rota não encontrada' });
};
