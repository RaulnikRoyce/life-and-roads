const express = require('express');
const router = express.Router();
const manutencaoController = require('../controllers/manutencao.controller');
const { verificarToken } = require('../middlewares/auth.middleware');
const { validarSchema } = require('../middlewares/validador');
const { manutencaoSchema } = require('../schemas/manutencao.schema');

router.get('/', verificarToken, manutencaoController.obter);
router.put('/', verificarToken, validarSchema(manutencaoSchema), manutencaoController.salvar);

module.exports = router;
