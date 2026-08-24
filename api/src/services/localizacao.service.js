const localizacaoRepository = require('../repositories/localizacao.repository');
const { AppError } = require('../utils/erros');

exports.obter = async (usuarioId) => {
    const ponto = await localizacaoRepository.buscarPorUsuario(usuarioId);
    if (!ponto) {
        throw new AppError(404, 'Nenhum ponto ainda');
    }
    return ponto;
};

exports.salvar = (usuarioId, dados) => localizacaoRepository.salvar(usuarioId, dados);
