const manutencaoService = require('../services/manutencao.service');
const { asyncHandler } = require('../utils/erros');
const { ok } = require('../utils/resposta');

exports.obter = asyncHandler(async (req, res) => {
    ok(res, await manutencaoService.obter(req.usuario.id));
});

exports.salvar = asyncHandler(async (req, res) => {
    ok(res, await manutencaoService.salvar(req.usuario.id, req.body));
});
