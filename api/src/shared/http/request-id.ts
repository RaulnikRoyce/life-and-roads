import { randomUUID } from 'crypto';
import type { Request, Response, NextFunction } from 'express';

export const requestId = (
  req: Request,
  res: Response,
  next: NextFunction,
): void => {
  const recebido = req.get('x-request-id');
  req.requestId = recebido && recebido.trim() ? recebido.trim().slice(0, 64) : randomUUID();
  res.setHeader('X-Request-Id', req.requestId);
  next();
};
