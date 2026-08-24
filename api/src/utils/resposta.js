const ok = (res, dados, status = 200) => res.status(status).json(dados);

const criado = (res, mensagem, extra = {}) =>
    res.status(201).json({ mensagem, ...extra });

module.exports = { ok, criado };
