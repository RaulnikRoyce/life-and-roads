const dns = require('dns');
const mysql = require('mysql2');

dns.setDefaultResultOrder('ipv4first');

const host = process.env.DB_HOST || '';
const porta = Number(process.env.DB_PORT) || 3306;

const pool = mysql.createPool({
    host,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: porta,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    connectTimeout: 20000
});

if (process.env.NODE_ENV !== 'test') {
    pool.getConnection((err, connection) => {
        if (err) {
            console.error(JSON.stringify({
                nivel: 'error',
                mensagem: 'Erro ao conectar no banco',
                detalhe: err.message,
                codigo: err.code,
                em: new Date().toISOString()
            }));
            return;
        }
        console.log(JSON.stringify({
            nivel: 'info',
            mensagem: 'Banco conectado',
            host,
            porta,
            em: new Date().toISOString()
        }));
        connection.release();
    });
}

module.exports = pool;
