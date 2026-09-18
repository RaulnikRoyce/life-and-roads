import { after, test } from 'node:test';
import assert from 'node:assert/strict';
import app from '../src/app';
import { fecharPool, pingBanco } from '../src/shared/database/pool';

after(() => fecharPool());

test('GET /health responde ok', async () => {
  const server = app.listen(0);
  const address = server.address();
  const port = typeof address === 'object' && address ? address.port : 0;

  try {
    const resposta = await fetch(`http://127.0.0.1:${port}/health`);
    const corpo = await resposta.json() as { status: string };
    assert.equal(resposta.status, 200);
    assert.equal(corpo.status, 'ok');
    assert.equal((corpo as { env?: string }).env, undefined);
    assert.ok(resposta.headers.get('x-request-id'));
  } finally {
    await new Promise<void>((resolve) => server.close(() => resolve()));
  }
});

test('GET /ready reflete o estado do MySQL', async () => {
  let bancoNoAr = true;
  try {
    await pingBanco();
  } catch {
    bancoNoAr = false;
  }

  const server = app.listen(0);
  const address = server.address();
  const port = typeof address === 'object' && address ? address.port : 0;

  try {
    const resposta = await fetch(`http://127.0.0.1:${port}/ready`);
    const corpo = await resposta.json() as { banco: boolean };
    assert.equal(resposta.status, bancoNoAr ? 200 : 503);
    assert.equal(corpo.banco, bancoNoAr);
  } finally {
    await new Promise<void>((resolve) => server.close(() => resolve()));
  }
});

test('POST /monitor/evento aceita crash curto', async () => {
  const server = app.listen(0);
  const address = server.address();
  const port = typeof address === 'object' && address ? address.port : 0;

  try {
    const resposta = await fetch(`http://127.0.0.1:${port}/monitor/evento`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        tipo: 'flutter_error',
        mensagem: 'Null check',
        ambiente: 'staging',
      }),
    });
    assert.equal(resposta.status, 200);
  } finally {
    await new Promise<void>((resolve) => server.close(() => resolve()));
  }
});

test('JSON malformado responde 400, não 500', async () => {
  const server = app.listen(0);
  const address = server.address();
  const port = typeof address === 'object' && address ? address.port : 0;

  try {
    const resposta = await fetch(`http://127.0.0.1:${port}/monitor/evento`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: '{"tipo": ',
    });
    const corpo = await resposta.json() as { erro: string };
    assert.equal(resposta.status, 400);
    assert.equal(corpo.erro, 'JSON inválido.');
  } finally {
    await new Promise<void>((resolve) => server.close(() => resolve()));
  }
});

test('corpo acima de 20 kb responde 413', async () => {
  const server = app.listen(0);
  const address = server.address();
  const port = typeof address === 'object' && address ? address.port : 0;

  try {
    const resposta = await fetch(`http://127.0.0.1:${port}/monitor/evento`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ tipo: 'flutter_error', mensagem: 'x'.repeat(30000) }),
    });
    const corpo = await resposta.json() as { erro: string };
    assert.equal(resposta.status, 413);
    assert.equal(corpo.erro, 'Corpo da requisição grande demais.');
  } finally {
    await new Promise<void>((resolve) => server.close(() => resolve()));
  }
});

