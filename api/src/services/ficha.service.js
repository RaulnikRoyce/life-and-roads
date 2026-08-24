const fichaRepository = require('../repositories/ficha.repository');
const { AppError } = require('../utils/erros');

exports.obter = async (usuarioId) => {
    const ficha = await fichaRepository.buscarPorUsuario(usuarioId);
    if (!ficha) {
        throw new AppError(404, 'Nenhuma ficha ainda');
    }
    return ficha;
};

exports.salvar = (usuarioId, dados) => fichaRepository.salvar(usuarioId, dados);
