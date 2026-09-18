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

  // express.json() lança erro pronto com status 4xx (JSON quebrado, corpo
  // grande, charset estranho). É culpa do cliente; não é falha nossa.
  const status = err && typeof err === 'object' && 'status' in err
    ? Number((err as { status: unknown }).status)
    : NaN;
  if (Number.isInteger(status) && status >= 400 && status < 500) {
    res.status(status).json({ erro: mensagemDoCliente(err, status) });
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

const mensagemDoCliente = (err: unknown, status: number): string => {
  const tipo = err && typeof err === 'object' && 'type' in err
    ? String((err as { type: unknown }).type)
    : '';
  if (tipo === 'entity.parse.failed') return 'JSON inválido.';
  if (status === 413) return 'Corpo da requisição grande demais.';
  if (tipo === 'charset.unsupported' || tipo === 'encoding.unsupported') {
    return 'Codificação não suportada. Use UTF-8.';
  }
  return 'Requisição inválida.';
};

export const rotaNaoEncontrada = (req: Request, res: Response): void => {
  res.status(404).json({ erro: 'Rota não encontrada' });
};
