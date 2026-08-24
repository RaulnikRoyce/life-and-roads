const db = require('../database/db');

const paraJson = (linha) => {
    if (!linha) return null;
    return {
        latitude: Number(linha.latitude),
        longitude: Number(linha.longitude)
    };
};

exports.buscarPorUsuario = (usuarioId) => new Promise((resolve, reject) => {
    db.query(
        'SELECT latitude, longitude FROM localizacoes WHERE usuario_id = ?',
        [usuarioId],
        (err, resultados) => {
            if (err) return reject(err);
            resolve(paraJson(resultados[0]));
        }
    );
});

exports.salvar = (usuarioId, dados) => new Promise((resolve, reject) => {
    db.query(
        `INSERT INTO localizacoes (usuario_id, latitude, longitude)
         VALUES (?, ?, ?)
         ON DUPLICATE KEY UPDATE
            latitude = VALUES(latitude),
            longitude = VALUES(longitude)`,
        [usuarioId, dados.latitude, dados.longitude],
        (err) => {
            if (err) return reject(err);
            resolve(dados);
        }
    );
});
