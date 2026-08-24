const express = require('express');
const router = express.Router();
const fichaController = require('../controllers/ficha.controller');
const { verificarToken } = require('../middlewares/auth.middleware');
const { validarSchema } = require('../middlewares/validador');
const { fichaSchema } = require('../schemas/ficha.schema');

router.get('/', verificarToken, fichaController.obter);
router.put('/', verificarToken, validarSchema(fichaSchema), fichaController.salvar);

module.exports = router;
