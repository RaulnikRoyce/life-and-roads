import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { z } from 'zod';
import { validarSchema } from '../../shared/http/validador';
import { logger } from '../../shared/http/logger';
import { ok } from '../../shared/http/resposta';
import { asyncHandler } from '../../shared/errors';

const eventoSchema = z.object({
  tipo: z.enum(['flutter_error', 'flutter_zone']),
  mensagem: z.string().trim().min(1).max(500),
  ambiente: z.enum(['development', 'staging', 'production']).optional(),
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
  asyncHandler((req, res) => {
    const corpo = req.body as z.infer<typeof eventoSchema>;
    logger.error('crash_cliente', {
      request_id: req.requestId,
      tipo: corpo.tipo,
      mensagem: corpo.mensagem,
      ambiente: corpo.ambiente ?? 'desconhecido',
    });
    ok(res, { ok: true });
  }),
);

export default router;
