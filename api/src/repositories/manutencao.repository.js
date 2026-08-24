const db = require('../database/db');

const SELECT = `SELECT
  DATE_FORMAT(oleo_ultima, '%Y-%m-%d') AS oleo_ultima,
  DATE_FORMAT(oleo_proxima, '%Y-%m-%d') AS oleo_proxima,
  DATE_FORMAT(revisao_ultima, '%Y-%m-%d') AS revisao_ultima,
  DATE_FORMAT(pneus_ultima, '%Y-%m-%d') AS pneus_ultima,
  DATE_FORMAT(pneus_proxima, '%Y-%m-%d') AS pneus_proxima,
  DATE_FORMAT(ipva_proxima, '%Y-%m-%d') AS ipva_proxima,
  DATE_FORMAT(seguro_proxima, '%Y-%m-%d') AS seguro_proxima,
  DATE_FORMAT(licenciamento_proxima, '%Y-%m-%d') AS licenciamento_proxima
 FROM manutencoes WHERE usuario_id = ?`;

const paraJson = (linha) => {
    if (!linha) return null;
    return {
        oleoUltima: linha.oleo_ultima,
        oleoProxima: linha.oleo_proxima,
        revisaoUltima: linha.revisao_ultima,
        pneusUltima: linha.pneus_ultima,
        pneusProxima: linha.pneus_proxima,
        ipvaProxima: linha.ipva_proxima,
        seguroProxima: linha.seguro_proxima,
        licenciamentoProxima: linha.licenciamento_proxima
    };
};

exports.buscarPorUsuario = (usuarioId) => new Promise((resolve, reject) => {
    db.query(SELECT, [usuarioId], (err, resultados) => {
        if (err) return reject(err);
        resolve(paraJson(resultados[0]));
    });
});

exports.salvar = (usuarioId, dados) => new Promise((resolve, reject) => {
    const params = [
        usuarioId,
        dados.oleoUltima,
        dados.oleoProxima,
        dados.revisaoUltima,
        dados.pneusUltima,
        dados.pneusProxima,
        dados.ipvaProxima,
        dados.seguroProxima,
        dados.licenciamentoProxima
    ];

    db.query(
        `INSERT INTO manutencoes
            (usuario_id, oleo_ultima, oleo_proxima, revisao_ultima, pneus_ultima, pneus_proxima,
             ipva_proxima, seguro_proxima, licenciamento_proxima)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE
            oleo_ultima = VALUES(oleo_ultima),
            oleo_proxima = VALUES(oleo_proxima),
            revisao_ultima = VALUES(revisao_ultima),
            pneus_ultima = VALUES(pneus_ultima),
            pneus_proxima = VALUES(pneus_proxima),
            ipva_proxima = VALUES(ipva_proxima),
            seguro_proxima = VALUES(seguro_proxima),
            licenciamento_proxima = VALUES(licenciamento_proxima)`,
        params,
        (err) => {
            if (err) return reject(err);
            resolve(dados);
        }
    );
});
