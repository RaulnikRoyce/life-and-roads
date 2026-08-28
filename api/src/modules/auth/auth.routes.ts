import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { validarSchema } from '../../shared/http/validador';
import { verificarToken } from '../../shared/http/auth';
import {
  loginSchema,
  refreshSchema,
  registrarSchema,
  sairSchema,
  senhaSchema,
} from './auth.schema';
import * as authController from './auth.controller';

const router = Router();

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { erro: 'Muitas tentativas. Aguarde 15 minutos.' },
});

router.post('/login', authLimiter, validarSchema(loginSchema), authController.login);
router.post('/registrar', authLimiter, validarSchema(registrarSchema), authController.registrar);
router.post('/refresh', authLimiter, validarSchema(refreshSchema), authController.refresh);
router.post('/sair', validarSchema(sairSchema), authController.sair);
router.post(
  '/senha',
  verificarToken,
  authLimiter,
  validarSchema(senhaSchema),
  authController.senha,
);
router.delete('/conta', verificarToken, authController.excluirConta);

export default router;
