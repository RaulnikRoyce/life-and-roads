exports.validarSchema = (schema) => (req, res, next) => {
    const validacao = schema.safeParse(req.body);

    if (!validacao.success) {
        const listaErros = validacao.error.issues || [];
        return res.status(400).json({
            erro: 'Dados inválidos',
            detalhes: listaErros.map((err) => ({
                campo: err.path[0] || 'geral',
                mensagem: err.message
            }))
        });
    }

    req.body = validacao.data;
    next();
};
