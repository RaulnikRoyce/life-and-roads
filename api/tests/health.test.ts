import { test } from 'node:test';
import assert from 'node:assert/strict';
import app from '../src/app';

test('GET /health responde ok', async () => {
  const server = app.listen(0);
  const address = server.address();
  const port = typeof address === 'object' && address ? address.port : 0;

  try {
    const resposta = await fetch(`http://127.0.0.1:${port}/health`);
    const corpo = await resposta.json() as { status: string };
    assert.equal(resposta.status, 200);
    assert.equal(corpo.status, 'ok');
    assert.equal((corpo as { env?: string }).env, 'development');
    assert.ok(resposta.headers.get('x-request-id'));
  } finally {
    await new Promise<void>((resolve) => server.close(() => resolve()));
  }
});

test('GET /ready com banco de teste fake devolve 503', async () => {
  const server = app.listen(0);
  const address = server.address();
  const port = typeof address === 'object' && address ? address.port : 0;

  try {
    const resposta = await fetch(`http://127.0.0.1:${port}/ready`);
    assert.equal(resposta.status, 503);
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
