const manutencaoRepository = require('../repositories/manutencao.repository');
const { AppError } = require('../utils/erros');

exports.obter = async (usuarioId) => {
    const manutencao = await manutencaoRepository.buscarPorUsuario(usuarioId);
    if (!manutencao) {
        throw new AppError(404, 'Nenhuma manutenção ainda');
    }
    return manutencao;
};

exports.salvar = (usuarioId, dados) => manutencaoRepository.salvar(usuarioId, dados);
