import { test } from 'node:test';
import assert from 'node:assert/strict';
import app from '../../src/app';
import { pingBanco } from '../../src/shared/database/pool';
import { migrar } from '../../src/shared/database/migrar';

const ficha = {
  marca: 'Honda',
  modelo: 'CG 160',
  ano: 2020,
  cilindrada: 160,
  kmLitro: 42,
  kmLitroAlcool: 30,
  combustivel: 'gasolina',
  kmAtual: 12000,
  tanqueLitros: 16.1,
  personalizacoes: '',
};

test('login, refresh, ficha e exclusão no MySQL', async (t) => {
  try {
    await pingBanco();
    await migrar();
  } catch {
    t.skip('MySQL indisponível neste ambiente');
    return;
  }

  const server = app.listen(0);
  const address = server.address();
  const port = typeof address === 'object' && address ? address.port : 0;
  const base = `http://127.0.0.1:${port}`;
  const email = `fase3.${Date.now()}@teste.local`;

  try {
    const reg = await fetch(`${base}/auth/registrar`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email, senha: 'senha1234' }),
    });
    assert.equal(reg.status, 201);

    const login = await fetch(`${base}/auth/login`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email, senha: 'senha1234' }),
    });
    assert.equal(login.status, 200);
    const sessao = await login.json() as {
      token: string;
      refreshToken: string;
      expiresIn: number;
    };
    assert.ok(sessao.token);
    assert.ok(sessao.refreshToken);
    assert.equal(sessao.expiresIn, 900);

    const placa = await fetch(`${base}/ficha`, {
      method: 'PUT',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${sessao.token}`,
      },
      body: JSON.stringify({ ...ficha, placa: 'ABC1D23' }),
    });
    assert.equal(placa.status, 400);

    const put = await fetch(`${base}/ficha`, {
      method: 'PUT',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${sessao.token}`,
      },
      body: JSON.stringify(ficha),
    });
    assert.equal(put.status, 200);

    const renovar = () => fetch(`${base}/auth/refresh`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ refreshToken: sessao.refreshToken }),
    });
    const concorrentes = await Promise.all([renovar(), renovar()]);
    assert.deepEqual(
      concorrentes.map((resposta) => resposta.status).sort(),
      [200, 401],
    );
    const respostaNova = concorrentes.find((resposta) => resposta.status === 200)!;
    const novo = await respostaNova.json() as { token: string; refreshToken: string };
    assert.ok(novo.token);
    assert.notEqual(novo.refreshToken, sessao.refreshToken);

    const del = await fetch(`${base}/auth/conta`, {
      method: 'DELETE',
      headers: { authorization: `Bearer ${novo.token}` },
    });
    assert.equal(del.status, 200);

    const depois = await fetch(`${base}/ficha`, {
      headers: { authorization: `Bearer ${novo.token}` },
    });
    assert.equal(depois.status, 401);
  } finally {
    await new Promise<void>((resolve) => server.close(() => resolve()));
  }
});

test('troca de senha revoga refresh e emite par novo', async (t) => {
  try {
    await pingBanco();
    await migrar();
  } catch {
    t.skip('MySQL indisponível neste ambiente');
    return;
  }

  const server = app.listen(0);
  const address = server.address();
  const port = typeof address === 'object' && address ? address.port : 0;
  const base = `http://127.0.0.1:${port}`;
  const email = `fase9.${Date.now()}@teste.local`;

  try {
    const reg = await fetch(`${base}/auth/registrar`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email, senha: 'senha1234' }),
    });
    assert.equal(reg.status, 201);

    const loginA = await fetch(`${base}/auth/login`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email, senha: 'senha1234' }),
    });
    assert.equal(loginA.status, 200);
    const aparelhoA = await loginA.json() as { token: string; refreshToken: string };

    const loginB = await fetch(`${base}/auth/login`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email, senha: 'senha1234' }),
    });
    assert.equal(loginB.status, 200);
    const aparelhoB = await loginB.json() as { token: string; refreshToken: string };

    const semToken = await fetch(`${base}/auth/senha`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ senhaAtual: 'senha1234', senhaNova: 'senha5678' }),
    });
    assert.equal(semToken.status, 401);

    const extra = await fetch(`${base}/auth/senha`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${aparelhoA.token}`,
      },
      body: JSON.stringify({
        senhaAtual: 'senha1234',
        senhaNova: 'senha5678',
        email,
      }),
    });
    assert.equal(extra.status, 400);

    const errada = await fetch(`${base}/auth/senha`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${aparelhoA.token}`,
      },
      body: JSON.stringify({ senhaAtual: 'senha9999', senhaNova: 'senha5678' }),
    });
    assert.equal(errada.status, 401);

    const troca = await fetch(`${base}/auth/senha`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${aparelhoA.token}`,
      },
      body: JSON.stringify({ senhaAtual: 'senha1234', senhaNova: 'senha5678' }),
    });
    assert.equal(troca.status, 200);
    const nova = await troca.json() as { token: string; refreshToken: string };
    assert.ok(nova.token);
    assert.ok(nova.refreshToken);
    assert.notEqual(nova.refreshToken, aparelhoA.refreshToken);

    const refreshVelhoA = await fetch(`${base}/auth/refresh`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ refreshToken: aparelhoA.refreshToken }),
    });
    assert.equal(refreshVelhoA.status, 401);

    const refreshVelhoB = await fetch(`${base}/auth/refresh`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ refreshToken: aparelhoB.refreshToken }),
    });
    assert.equal(refreshVelhoB.status, 401);

    const refreshNovo = await fetch(`${base}/auth/refresh`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ refreshToken: nova.refreshToken }),
    });
    assert.equal(refreshNovo.status, 200);

    const loginAntiga = await fetch(`${base}/auth/login`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email, senha: 'senha1234' }),
    });
    assert.equal(loginAntiga.status, 401);

    const loginNova = await fetch(`${base}/auth/login`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email, senha: 'senha5678' }),
    });
    assert.equal(loginNova.status, 200);

    const sessaoNova = await loginNova.json() as { token: string };
    const del = await fetch(`${base}/auth/conta`, {
      method: 'DELETE',
      headers: { authorization: `Bearer ${sessaoNova.token}` },
    });
    assert.equal(del.status, 200);
  } finally {
    await new Promise<void>((resolve) => server.close(() => resolve()));
  }
});
