const express = require('express');
const router = express.Router();
const localizacaoController = require('../controllers/localizacao.controller');
const { verificarToken } = require('../middlewares/auth.middleware');
const { validarSchema } = require('../middlewares/validador');
const { localizacaoSchema } = require('../schemas/localizacao.schema');

router.get('/', verificarToken, localizacaoController.obter);
router.put('/', verificarToken, validarSchema(localizacaoSchema), localizacaoController.salvar);

module.exports = router;
