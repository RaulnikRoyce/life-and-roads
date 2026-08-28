import type { Request, Response, NextFunction } from 'express';
import type { ZodType } from 'zod';

export const validarSchema = (schema: ZodType) => (
  req: Request,
  res: Response,
  next: NextFunction,
): void => {
  const validacao = schema.safeParse(req.body);

  if (!validacao.success) {
    const listaErros = validacao.error.issues || [];
    res.status(400).json({
      erro: 'Dados inválidos',
      detalhes: listaErros.map((err) => ({
        campo: err.path[0] || 'geral',
        mensagem: err.message,
      })),
    });
    return;
  }

  req.body = validacao.data;
  next();
};
