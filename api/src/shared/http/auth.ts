import type { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import {
  getJwtSecret,
  JWT_ALGORITHM,
  JWT_AUDIENCE,
  JWT_ISSUER,
} from '../config/jwt';
import { buscarPorId } from '../../modules/auth/auth.repository';

type JwtAccess = { id?: unknown; typ?: unknown };

export const verificarToken = async (
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> => {
  const authorization = req.get('authorization');

  if (!authorization || !authorization.startsWith('Bearer ')) {
    res.status(401).json({ erro: 'Token não fornecido.' });
    return;
  }

  const token = authorization.slice(7).trim();
  if (!token) {
    res.status(401).json({ erro: 'Token não fornecido.' });
    return;
  }

  try {
    const decoded = jwt.verify(token, getJwtSecret(), {
      algorithms: [JWT_ALGORITHM],
      issuer: JWT_ISSUER,
      audience: JWT_AUDIENCE,
    }) as JwtAccess;
    if (decoded.typ !== 'access') {
      res.status(401).json({ erro: 'Token inválido ou expirado.' });
      return;
    }
    const id = Number(decoded.id);
    if (!Number.isInteger(id) || id <= 0) {
      res.status(401).json({ erro: 'Token inválido ou expirado.' });
      return;
    }
    const usuario = await buscarPorId(id);
    if (!usuario) {
      res.status(401).json({ erro: 'Token inválido ou expirado.' });
      return;
    }
    if (!usuario.ativo) {
      res.status(403).json({ erro: 'Conta desativada.' });
      return;
    }
    req.usuario = { id };
    next();
  } catch {
    res.status(401).json({ erro: 'Token inválido ou expirado.' });
  }
};
