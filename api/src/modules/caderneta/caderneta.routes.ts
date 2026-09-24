import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { verificarToken } from '../../shared/http/auth';
import { validarSchema } from '../../shared/http/validador';
import { salvarCadernetaSchema } from './caderneta.schema';
import * as cadernetaController from './caderneta.controller';

/**
 * O app espera minutos sem mudança antes de mandar, então 30 envios em 15
 * minutos só acontecem por defeito ou abuso, e o plano grátis agradece. O
 * limite é por conta, não por IP, e vem do ambiente só para o teste poder
 * provar que ele existe sem fazer 31 chamadas.
 */
const limiteEnvios = Number(process.env.CADERNETA_LIMITE_ENVIOS) || 30;

const envios = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: limiteEnvios,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => `caderneta:${req.usuario!.id}`,
  message: { erro: 'Muitos envios da caderneta. Aguarde alguns minutos.' },
});

const router = Router();
router.get('/', verificarToken, cadernetaController.obter);
router.put(
  '/',
  verificarToken,
  envios,
  validarSchema(salvarCadernetaSchema),
  cadernetaController.salvar,
);
router.delete('/', verificarToken, cadernetaController.apagar);
export default router;
