const db = require('../database/db');

exports.buscarPorEmail = (email) => new Promise((resolve, reject) => {
    db.query('SELECT * FROM usuarios WHERE email = ?', [email], (err, resultados) => {
        if (err) return reject(err);
        resolve(resultados[0] || null);
    });
});

exports.salvar = (email, senhaCriptografada) => new Promise((resolve, reject) => {
    db.query(
        'INSERT INTO usuarios (email, senha) VALUES (?, ?)',
        [email, senhaCriptografada],
        (err, result) => {
            if (err) return reject(err);
            resolve({ id: result.insertId, email, ativo: 1 });
        }
    );
});
