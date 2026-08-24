const jwt = require('jsonwebtoken');
const authService = require('../services/auth.service');
const { getJwtSecret } = require('../config/jwt');
const { asyncHandler, AppError } = require('../utils/erros');
const { criado } = require('../utils/resposta');

exports.login = asyncHandler(async (req, res) => {
    const { email, senha } = req.body;
    const usuario = await authService.autenticar(email, senha);

    if (!usuario) {
        throw new AppError(401, 'Credenciais inválidas');
    }

    const token = jwt.sign({ id: usuario.id }, getJwtSecret(), { expiresIn: '8h' });

    res.json({
        mensagem: 'Login realizado',
        token,
        email: usuario.email,
        id: usuario.id
    });
});

exports.registrar = asyncHandler(async (req, res) => {
    const { email, senha } = req.body;
    await authService.registrar(email, senha);
    criado(res, 'Conta criada');
});
