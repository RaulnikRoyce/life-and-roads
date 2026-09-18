import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { z } from 'zod';
import { validarSchema } from '../../shared/http/validador';
import { logger } from '../../shared/http/logger';
import { ok } from '../../shared/http/resposta';
import { asyncHandler } from '../../shared/errors';
import { gravarEvento } from './monitor.repository';

const opcional = (max: number) => z.preprocess(
  (v) => (v === '' || v === undefined ? null : v),
  z.string().trim().max(max).nullable(),
);

// Só contexto técnico. Nada de e-mail, ficha ou posição.
const eventoSchema = z.object({
  tipo: z.enum(['flutter_error', 'flutter_zone']),
  mensagem: z.string().trim().min(1).max(500),
  ambiente: z.enum(['development', 'staging', 'production']).optional(),
  versaoApp: opcional(40).optional(),
  plataforma: opcional(80).optional(),
  pilha: opcional(2000).optional(),
}).strict();

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { erro: 'Muitas tentativas. Aguarde 15 minutos.' },
});

const router = Router();

router.post(
  '/evento',
  limiter,
  validarSchema(eventoSchema),
  asyncHandler(async (req, res) => {
    const corpo = req.body as z.infer<typeof eventoSchema>;
    logger.error('crash_cliente', {
      request_id: req.requestId,
      tipo: corpo.tipo,
      mensagem: corpo.mensagem,
      ambiente: corpo.ambiente ?? 'desconhecido',
      versao_app: corpo.versaoApp ?? null,
      plataforma: corpo.plataforma ?? null,
    });
    // Banco fora do ar não pode derrubar o relato: o log já ficou.
    try {
      await gravarEvento({
        tipo: corpo.tipo,
        mensagem: corpo.mensagem,
        ambiente: corpo.ambiente ?? null,
        versaoApp: corpo.versaoApp ?? null,
        plataforma: corpo.plataforma ?? null,
        pilha: corpo.pilha ?? null,
      });
    } catch (erro) {
      logger.error('crash_cliente_sem_banco', {
        request_id: req.requestId,
        detalhe: erro instanceof Error ? erro.message : 'erro',
      });
    }
    ok(res, { ok: true });
  }),
);

export default router;
