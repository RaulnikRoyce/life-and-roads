import { after, test, type TestContext } from 'node:test';
import assert from 'node:assert/strict';
import app from '../../src/app';
import { fecharPool, getPool, pingBanco } from '../../src/shared/database/pool';
import { apagarSessoesVencidas } from '../../src/modules/auth/auth.repository';
import { migrar } from '../../src/shared/database/migrar';

// Sem isto o pool segura o processo aberto até o idle timeout do mysql2.
after(() => fecharPool());

/** Local sem MySQL: pula. CI sem MySQL: falha, para o job não ficar verde à toa. */
const bancoPronto = async (t: TestContext): Promise<boolean> => {
  try {
    await pingBanco();
    await migrar();
    return true;
  } catch (erro) {
    if (process.env.CI === 'true') throw erro;
    t.skip('MySQL indisponível neste ambiente');
    return false;
  }
};

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
  if (!await bancoPronto(t)) return;

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
    // Abas do app renovando juntas com o mesmo refresh: as duas passam.
    const concorrentes = await Promise.all([renovar(), renovar()]);
    assert.deepEqual(
      concorrentes.map((resposta) => resposta.status),
      [200, 200],
    );
    const pares = await Promise.all(
      concorrentes.map((r) => r.json() as Promise<{ token: string; refreshToken: string }>),
    );
    const novo = pares[0];
    assert.ok(novo.token);
    assert.notEqual(novo.refreshToken, sessao.refreshToken);
    assert.notEqual(pares[1].refreshToken, novo.refreshToken);

    // Sair deste aparelho: só este refresh cai; o outro par segue válido.
    const loginB = await fetch(`${base}/auth/login`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email, senha: 'senha1234' }),
    });
    const aparelhoB = await loginB.json() as { refreshToken: string };
    const sair = await fetch(`${base}/auth/sair`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ refreshToken: novo.refreshToken }),
    });
    assert.equal(sair.status, 200);
    const depoisDeSair = await fetch(`${base}/auth/refresh`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ refreshToken: novo.refreshToken }),
    });
    assert.equal(depoisDeSair.status, 401);
    const bSegue = await fetch(`${base}/auth/refresh`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ refreshToken: aparelhoB.refreshToken }),
    });
    assert.equal(bSegue.status, 200);

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
  if (!await bancoPronto(t)) return;

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

test('refresh rotacionado fora da janela é roubo e revoga a conta', async (t) => {
  if (!await bancoPronto(t)) return;

  const server = app.listen(0);
  const address = server.address();
  const port = typeof address === 'object' && address ? address.port : 0;
  const base = `http://127.0.0.1:${port}`;
  const email = `roubo.${Date.now()}@teste.local`;
  const json = { 'content-type': 'application/json' };

  try {
    await fetch(`${base}/auth/registrar`, {
      method: 'POST', headers: json, body: JSON.stringify({ email, senha: 'senha1234' }),
    });
    const login = await fetch(`${base}/auth/login`, {
      method: 'POST', headers: json, body: JSON.stringify({ email, senha: 'senha1234' }),
    });
    const antigo = await login.json() as { refreshToken: string };

    const primeira = await fetch(`${base}/auth/refresh`, {
      method: 'POST', headers: json, body: JSON.stringify({ refreshToken: antigo.refreshToken }),
    });
    assert.equal(primeira.status, 200);
    const atual = await primeira.json() as { refreshToken: string };

    // Simula o tempo passando: a rotação foi há 60 s, fora da tolerância.
    await getPool().execute(
      `UPDATE sessoes s JOIN usuarios u ON u.id = s.usuario_id
          SET s.rotacionada_em = NOW() - INTERVAL 60 SECOND
        WHERE u.email = ? AND s.rotacionada_em IS NOT NULL`,
      [email],
    );

    const reuso = await fetch(`${base}/auth/refresh`, {
      method: 'POST', headers: json, body: JSON.stringify({ refreshToken: antigo.refreshToken }),
    });
    assert.equal(reuso.status, 401);

    // A conta inteira caiu, inclusive o par legítimo.
    const legitimo = await fetch(`${base}/auth/refresh`, {
      method: 'POST', headers: json, body: JSON.stringify({ refreshToken: atual.refreshToken }),
    });
    assert.equal(legitimo.status, 401);

    const loginDeNovo = await fetch(`${base}/auth/login`, {
      method: 'POST', headers: json, body: JSON.stringify({ email, senha: 'senha1234' }),
    });
    assert.equal(loginDeNovo.status, 200);
    const sessao = await loginDeNovo.json() as { token: string };
    const del = await fetch(`${base}/auth/conta`, {
      method: 'DELETE', headers: { authorization: `Bearer ${sessao.token}` },
    });
    assert.equal(del.status, 200);
  } finally {
    await new Promise<void>((resolve) => server.close(() => resolve()));
  }
});

test('limpeza apaga só sessões vencidas', async (t) => {
  if (!await bancoPronto(t)) return;
  const email = `limpeza.${Date.now()}@teste.local`;
  const pool = getPool();
  const [u] = await pool.execute<import('mysql2').ResultSetHeader>(
    'INSERT INTO usuarios (email, senha) VALUES (?, ?)',
    [email, 'x'],
  );
  try {
    await pool.execute(
      `INSERT INTO sessoes (usuario_id, token_hash, expira_em) VALUES
         (?, ?, UTC_TIMESTAMP() - INTERVAL 1 DAY),
         (?, ?, UTC_TIMESTAMP() + INTERVAL 1 DAY)`,
      [u.insertId, `vencida-${u.insertId}`, u.insertId, `viva-${u.insertId}`],
    );
    await apagarSessoesVencidas();
    const [rows] = await pool.execute<import('mysql2').RowDataPacket[]>(
      'SELECT token_hash FROM sessoes WHERE usuario_id = ?',
      [u.insertId],
    );
    assert.deepEqual(rows.map((r) => r.token_hash), [`viva-${u.insertId}`]);
  } finally {
    await pool.execute('DELETE FROM usuarios WHERE id = ?', [u.insertId]);
  }
});

