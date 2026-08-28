import { Router } from 'express';
import { verificarToken } from '../../shared/http/auth';
import { validarSchema } from '../../shared/http/validador';
import { manutencaoSchema } from './manutencao.schema';
import * as manutencaoController from './manutencao.controller';

const router = Router();
router.get('/', verificarToken, manutencaoController.obter);
router.put('/', verificarToken, validarSchema(manutencaoSchema), manutencaoController.salvar);
export default router;
