if (process.env.NODE_ENV !== 'production') {
    require('dotenv').config();
    require('dotenv').config({ path: '.env.local', override: true });
}

const { carregarEnv } = require('./src/config/env');

let env;
try {
    env = carregarEnv();
} catch (erro) {
    console.error(JSON.stringify({
        nivel: 'error',
        mensagem: erro.message,
        em: new Date().toISOString()
    }));
    process.exit(1);
}

const app = require('./src/app');

app.listen(env.port, '0.0.0.0', () => {
    console.log(JSON.stringify({
        nivel: 'info',
        mensagem: `API life.and.roads em 0.0.0.0:${env.port}`,
        em: new Date().toISOString()
    }));
});
