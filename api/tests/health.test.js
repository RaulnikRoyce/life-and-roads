const test = require('node:test');
const assert = require('node:assert/strict');
const app = require('../src/app');

test('GET /health responde ok', async () => {
    const server = app.listen(0);
    const { port } = server.address();

    try {
        const resposta = await fetch(`http://127.0.0.1:${port}/health`);
        const corpo = await resposta.json();
        assert.equal(resposta.status, 200);
        assert.equal(corpo.status, 'ok');
    } finally {
        await new Promise((resolve) => server.close(resolve));
    }
});
