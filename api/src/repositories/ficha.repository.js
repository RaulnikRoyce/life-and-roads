const db = require('../database/db');

const paraJson = (linha) => {
    if (!linha) return null;
    return {
        marca: linha.marca,
        modelo: linha.modelo,
        ano: linha.ano,
        cilindrada: linha.cilindrada,
        kmLitro: Number(linha.km_litro),
        kmLitroAlcool: linha.km_litro_alcool == null ? null : Number(linha.km_litro_alcool),
        combustivel: linha.combustivel === 'alcool' ? 'alcool' : 'gasolina',
        kmAtual: Number(linha.km_atual),
        tanqueLitros: linha.tanque_litros == null ? null : Number(linha.tanque_litros),
        personalizacoes: linha.personalizacoes || ''
    };
};

exports.buscarPorUsuario = (usuarioId) => new Promise((resolve, reject) => {
    db.query(
        'SELECT marca, modelo, ano, cilindrada, km_litro, km_litro_alcool, combustivel, km_atual, tanque_litros, personalizacoes FROM fichas WHERE usuario_id = ?',
        [usuarioId],
        (err, resultados) => {
            if (err) return reject(err);
            resolve(paraJson(resultados[0]));
        }
    );
});

exports.salvar = (usuarioId, dados) => new Promise((resolve, reject) => {
    const params = [
        usuarioId,
        dados.marca,
        dados.modelo,
        dados.ano,
        dados.cilindrada,
        dados.kmLitro,
        dados.kmLitroAlcool ?? null,
        dados.combustivel === 'alcool' ? 'alcool' : 'gasolina',
        dados.kmAtual,
        dados.tanqueLitros ?? null,
        dados.personalizacoes || ''
    ];

    db.query(
        `INSERT INTO fichas
            (usuario_id, marca, modelo, ano, cilindrada, km_litro, km_litro_alcool, combustivel, km_atual, tanque_litros, personalizacoes)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE
            marca = VALUES(marca),
            modelo = VALUES(modelo),
            ano = VALUES(ano),
            cilindrada = VALUES(cilindrada),
            km_litro = VALUES(km_litro),
            km_litro_alcool = VALUES(km_litro_alcool),
            combustivel = VALUES(combustivel),
            km_atual = VALUES(km_atual),
            tanque_litros = VALUES(tanque_litros),
            personalizacoes = VALUES(personalizacoes)`,
        params,
        (err) => {
            if (err) return reject(err);
            resolve(dados);
        }
    );
});
