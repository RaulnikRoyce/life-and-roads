const log = (nivel, mensagem, extra = {}) => {
    const linha = JSON.stringify({
        nivel,
        mensagem,
        em: new Date().toISOString(),
        ...extra
    });
    if (nivel === 'error') {
        console.error(linha);
        return;
    }
    console.log(linha);
};

module.exports = {
    info: (mensagem, extra) => log('info', mensagem, extra),
    error: (mensagem, extra) => log('error', mensagem, extra)
};
