const logger = require('../utils/logger');
const { AppError } = require('../utils/erros');

exports.manipularErros = (err, req, res, next) => {
    if (res.headersSent) {
        return next(err);
    }

    if (err instanceof AppError) {
        const corpo = { erro: err.message };
        if (err.detalhes) corpo.detalhes = err.detalhes;
        return res.status(err.status).json(corpo);
    }

    if (err.code === 'ER_DUP_ENTRY') {
        return res.status(409).json({ erro: 'E-mail já cadastrado' });
    }

    logger.error('Erro não tratado', {
        rota: req.originalUrl,
        metodo: req.method,
        detalhe: err.message
    });

    return res.status(500).json({ erro: 'Erro interno do servidor' });
};

exports.rotaNaoEncontrada = (req, res) => {
    res.status(404).json({ erro: 'Rota não encontrada' });
};
