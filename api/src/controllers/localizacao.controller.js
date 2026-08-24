const localizacaoService = require('../services/localizacao.service');
const { asyncHandler } = require('../utils/erros');
const { ok } = require('../utils/resposta');

exports.obter = asyncHandler(async (req, res) => {
    ok(res, await localizacaoService.obter(req.usuario.id));
});

exports.salvar = asyncHandler(async (req, res) => {
    ok(res, await localizacaoService.salvar(req.usuario.id, req.body));
});
