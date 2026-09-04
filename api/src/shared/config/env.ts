/**
 * Carrega e valida as variáveis de ambiente obrigatórias.
 * Ausência de DB_HOST, DB_USER, DB_NAME ou JWT_SECRET encerra o processo.
 */
function limpar(valor: unknown): string {
  return String(valor || '').trim().replace(/^['"]|['"]$/g, '');
}

export type Env = {
  port: number;
  dbHost: string;
  dbPort: number;
  jwtSecret: string;
};

export const carregarEnv = (): Env => {
  const dbHost = limpar(process.env.DB_HOST);
  const dbUser = limpar(process.env.DB_USER);
  const dbName = limpar(process.env.DB_NAME);
  const dbPassword = limpar(process.env.DB_PASSWORD);
  const dbPort = limpar(process.env.DB_PORT) || '3306';
  const jwtSecret = limpar(process.env.JWT_SECRET);

  const faltando: string[] = [];
  if (!dbHost) faltando.push('DB_HOST');
  if (!dbUser) faltando.push('DB_USER');
  if (!dbName) faltando.push('DB_NAME');
  if (!jwtSecret) faltando.push('JWT_SECRET');

  if (faltando.length) {
    throw new Error(
      `Variável obrigatória ausente: ${faltando.join(', ')}. `
        + 'Modelo em api/.env.example. A API escuta na porta 3001.',
    );
  }

  if (Buffer.byteLength(jwtSecret, 'utf8') < 32) {
    throw new Error('JWT_SECRET deve ter pelo menos 32 bytes aleatórios.');
  }
  if (['troque-na-staging', 'troque-por-um-segredo-longo'].includes(jwtSecret)) {
    throw new Error('JWT_SECRET usa um valor de exemplo inseguro.');
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
    dbPort: Number(dbPort),
    jwtSecret,
  };
};

export { limpar };
