import { Router } from 'express';
import { verificarToken } from '../../shared/http/auth';
import { validarSchema } from '../../shared/http/validador';
import { fichaSchema } from './ficha.schema';
import * as fichaController from './ficha.controller';

const router = Router();
router.get('/', verificarToken, fichaController.obter);
router.put('/', verificarToken, validarSchema(fichaSchema), fichaController.salvar);
export default router;
