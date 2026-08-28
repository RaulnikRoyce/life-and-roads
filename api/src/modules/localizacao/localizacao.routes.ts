import { Router } from 'express';
import { verificarToken } from '../../shared/http/auth';
import { validarSchema } from '../../shared/http/validador';
import { localizacaoSchema } from './localizacao.schema';
import * as localizacaoController from './localizacao.controller';

const router = Router();
router.get('/', verificarToken, localizacaoController.obter);
router.put('/', verificarToken, validarSchema(localizacaoSchema), localizacaoController.salvar);
export default router;
