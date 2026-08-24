const fichaService = require('../services/ficha.service');
const { asyncHandler } = require('../utils/erros');
const { ok } = require('../utils/resposta');

exports.obter = asyncHandler(async (req, res) => {
    ok(res, await fichaService.obter(req.usuario.id));
});

exports.salvar = asyncHandler(async (req, res) => {
    ok(res, await fichaService.salvar(req.usuario.id, req.body), 200);
});
