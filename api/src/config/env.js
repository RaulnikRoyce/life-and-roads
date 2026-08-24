function limpar(valor) {
    return String(valor || '').trim().replace(/^['"]|['"]$/g, '');
}

const carregarEnv = () => {
    const dbHost = limpar(process.env.DB_HOST);
    const dbUser = limpar(process.env.DB_USER);
    const dbName = limpar(process.env.DB_NAME);
    const dbPassword = limpar(process.env.DB_PASSWORD);
    const dbPort = limpar(process.env.DB_PORT) || '3306';
    const jwtSecret = limpar(process.env.JWT_SECRET);

    const faltando = [];
    if (!dbHost) faltando.push('DB_HOST');
    if (!dbUser) faltando.push('DB_USER');
    if (!dbName) faltando.push('DB_NAME');
    if (!jwtSecret) faltando.push('JWT_SECRET');

    if (faltando.length) {
        throw new Error(
            `Variável obrigatória ausente: ${faltando.join(', ')}. `
            + 'Modelo em life-and-roads/api/.env.example. Porta 3001 (o Beco fica no 3000).'
        );
    }

    process.env.DB_HOST = dbHost;
    process.env.DB_USER = dbUser;
    process.env.DB_NAME = dbName;
    process.env.DB_PASSWORD = dbPassword;
    process.env.DB_PORT = dbPort;
    process.env.JWT_SECRET = jwtSecret;

    return {
        port: Number(process.env.PORT) || 3001,
        dbHost,
        dbPort: Number(dbPort)
    };
};

module.exports = { carregarEnv, limpar };
