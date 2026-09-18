// Ambiente dos testes. Sem MySQL, os testes de integração pulam localmente
// e falham no CI (CI=true). Valores abaixo são padrão; o CI sobrescreve.
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'segredo-somente-para-teste-com-32-bytes';
process.env.DB_HOST = process.env.DB_HOST || '127.0.0.1';
process.env.DB_USER = process.env.DB_USER || 'test';
process.env.DB_NAME = process.env.DB_NAME || 'test';
process.env.DB_PASSWORD = process.env.DB_PASSWORD || '';
process.env.DB_PORT = process.env.DB_PORT || '3306';
