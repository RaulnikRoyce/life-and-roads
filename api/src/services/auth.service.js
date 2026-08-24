const bcrypt = require('bcryptjs');
const authRepository = require('../repositories/auth.repository');
const { AppError } = require('../utils/erros');

exports.autenticar = async (email, senha) => {
    const usuario = await authRepository.buscarPorEmail(email);
    if (!usuario) return null;

    const senhaValida = await bcrypt.compare(senha, usuario.senha);
    if (!senhaValida) return null;

    if (!usuario.ativo) {
        throw new AppError(403, 'Conta desativada.');
    }

    return { id: usuario.id, email: usuario.email };
};

exports.registrar = async (email, senha) => {
    const existente = await authRepository.buscarPorEmail(email);
    if (existente) {
        throw new AppError(409, 'E-mail já cadastrado');
    }

    const senhaCriptografada = await bcrypt.hash(senha, 10);
    const criado = await authRepository.salvar(email, senhaCriptografada);
    return { id: criado.id, email: criado.email };
};
