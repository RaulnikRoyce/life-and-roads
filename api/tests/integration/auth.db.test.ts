import { after, test, type TestContext } from 'node:test';
import assert from 'node:assert/strict';
import app from '../../src/app';
import { fecharPool, getPool, pingBanco } from '../../src/shared/database/pool';
import {
  apagarRecuperacoesVencidas,
  apagarSessoesVencidas,
} from '../../src/modules/auth/auth.repository';
import { migrar } from '../../src/shared/database/migrar';
import {
  ASSUNTO_BOAS_VINDAS,
  ASSUNTO_CODIGO,
  usarTransporte,
  type Mensagem,
} from '../../src/shared/email/enviar_email';

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

const postJson = (base: string, rota: string, corpo: unknown) => fetch(`${base}${rota}`, {
  method: 'POST',
  headers: { 'content-type': 'application/json' },
  body: JSON.stringify(corpo),
});

/**
 * O envio não é aguardado pela rota, então o teste espera a mensagem cair
 * na caixa do transporte falso e tira o código de 6 dígitos do texto.
 */
/** Só os e-mails de código. A boas-vindas do cadastro também cai na caixa. */
const soCodigos = (caixa: Mensagem[]): Mensagem[] =>
  caixa.filter((m) => m.assunto === ASSUNTO_CODIGO);

const esperarCodigo = async (caixa: Mensagem[], para: string): Promise<string> => {
  for (let i = 0; i < 100; i += 1) {
    const mensagens = soCodigos(caixa).filter((m) => m.para === para);
    const ultima = mensagens[mensagens.length - 1];
    const achado = ultima ? /\b(\d{6})\b/.exec(ultima.texto) : null;
    if (achado) return achado[1];
    await new Promise((resolve) => setTimeout(resolve, 20));
  }
  throw new Error(`código não chegou ao transporte falso para ${para}`);
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

    // Carimbo do servidor: vem no PUT e no GET, iguais; não entra no PUT.
    const putCorpo = await put.json() as { atualizadoEm: string | null };
    assert.match(putCorpo.atualizadoEm ?? '', /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/);
    const get = await fetch(`${base}/ficha`, {
      headers: { authorization: `Bearer ${sessao.token}` },
    });
    assert.equal(get.status, 200);
    const getCorpo = await get.json() as { atualizadoEm: string | null; modelo: string };
    assert.equal(getCorpo.atualizadoEm, putCorpo.atualizadoEm);
    assert.equal(getCorpo.modelo, 'CG 160');
    const carimboNoPut = await fetch(`${base}/ficha`, {
      method: 'PUT',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${sessao.token}`,
      },
      body: JSON.stringify({ ...ficha, atualizadoEm: putCorpo.atualizadoEm }),
    });
    assert.equal(carimboNoPut.status, 400);

    const agenda = {
      oleoUltima: '2026-01-10', oleoProxima: '2026-07-10', revisaoUltima: null,
      pneusUltima: null, pneusProxima: null, ipvaProxima: null,
      seguroProxima: null, licenciamentoProxima: null,
    };
    const putAgenda = await fetch(`${base}/manutencao`, {
      method: 'PUT',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${sessao.token}`,
      },
      body: JSON.stringify(agenda),
    });
    assert.equal(putAgenda.status, 200);
    const agendaCorpo = await putAgenda.json() as { atualizadoEm: string | null };
    assert.ok(agendaCorpo.atualizadoEm);
    const getAgenda = await fetch(`${base}/manutencao`, {
      headers: { authorization: `Bearer ${sessao.token}` },
    });
    const getAgendaCorpo = await getAgenda.json() as { atualizadoEm: string | null };
    assert.equal(getAgendaCorpo.atualizadoEm, agendaCorpo.atualizadoEm);

    // Segundo PUT exercita o ON DUPLICATE KEY UPDATE da manutenção.
    const putAgenda2 = await fetch(`${base}/manutencao`, {
      method: 'PUT',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${sessao.token}`,
      },
      body: JSON.stringify({ ...agenda, ipvaProxima: '2027-03-31' }),
    });
    assert.equal(putAgenda2.status, 200);
    const agenda2 = await (await fetch(`${base}/manutencao`, {
      headers: { authorization: `Bearer ${sessao.token}` },
    })).json() as { ipvaProxima: string | null };
    assert.equal(agenda2.ipvaProxima, '2027-03-31');

    // Localização: insere, atualiza, lê.
    for (const ponto of [{ latitude: -23.55, longitude: -46.63 }, { latitude: -22.9, longitude: -43.2 }]) {
      const putPonto = await fetch(`${base}/localizacao`, {
        method: 'PUT',
        headers: {
          'content-type': 'application/json',
          authorization: `Bearer ${sessao.token}`,
        },
        body: JSON.stringify(ponto),
      });
      assert.equal(putPonto.status, 200);
    }
    const ponto = await (await fetch(`${base}/localizacao`, {
      headers: { authorization: `Bearer ${sessao.token}` },
    })).json() as { latitude: number; longitude: number };
    assert.equal(ponto.latitude, -22.9);
    assert.equal(ponto.longitude, -43.2);

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

test('cadastro manda uma boas-vindas, sem código e sem dado do piloto', async (t) => {
  if (!await bancoPronto(t)) return;
  const server = app.listen(0);
  const address = server.address();
  const port = typeof address === 'object' && address ? address.port : 0;
  const base = `http://127.0.0.1:${port}`;
  const email = `bemvindo.${Date.now()}@teste.local`;
  const caixa: Mensagem[] = [];
  usarTransporte(async (m) => { caixa.push(m); });

  try {
    const reg = await postJson(base, '/auth/registrar', { email, senha: 'senha1234' });
    assert.equal(reg.status, 201);

    // O envio não é aguardado pela rota; espera cair na caixa.
    for (let i = 0; i < 100 && caixa.length < 1; i += 1) {
      await new Promise((resolve) => setTimeout(resolve, 20));
    }
    await new Promise((resolve) => setTimeout(resolve, 50));
    assert.equal(caixa.length, 1, 'uma boas-vindas e nada mais');
    const [msg] = caixa;
    assert.equal(msg.para, email);
    assert.equal(msg.assunto, ASSUNTO_BOAS_VINDAS);
    assert.ok(!/\b\d{6}\b/.test(msg.texto), 'boas-vindas não leva código');
    assert.ok(!msg.texto.includes(email), 'o texto não repete o e-mail do piloto');

    // Cadastro repetido é recusado e não manda uma segunda boas-vindas.
    const repetido = await postJson(base, '/auth/registrar', { email, senha: 'senha1234' });
    assert.equal(repetido.status, 409);
    await new Promise((resolve) => setTimeout(resolve, 80));
    assert.equal(caixa.length, 1);
  } finally {
    usarTransporte(null);
    await getPool().execute('DELETE FROM usuarios WHERE email = ?', [email]);
    await new Promise<void>((resolve) => server.close(() => resolve()));
  }
});

test('cadastro dá certo mesmo se a boas-vindas falhar', async (t) => {
  if (!await bancoPronto(t)) return;
  const server = app.listen(0);
  const address = server.address();
  const port = typeof address === 'object' && address ? address.port : 0;
  const base = `http://127.0.0.1:${port}`;
  const email = `semcorreio.${Date.now()}@teste.local`;
  usarTransporte(async () => { throw new Error('provedor fora do ar'); });

  try {
    const reg = await postJson(base, '/auth/registrar', { email, senha: 'senha1234' });
    assert.equal(reg.status, 201);
    const login = await postJson(base, '/auth/login', { email, senha: 'senha1234' });
    assert.equal(login.status, 200, 'a conta existe e entra normalmente');
  } finally {
    usarTransporte(null);
    await getPool().execute('DELETE FROM usuarios WHERE email = ?', [email]);
    await new Promise<void>((resolve) => server.close(() => resolve()));
  }
});

test('recuperação por código redefine a senha e revoga as sessões', async (t) => {
  if (!await bancoPronto(t)) return;
  const server = app.listen(0);
  const address = server.address();
  const port = typeof address === 'object' && address ? address.port : 0;
  const base = `http://127.0.0.1:${port}`;
  const email = `recuperar.${Date.now()}@teste.local`;
  const caixa: Mensagem[] = [];
  usarTransporte(async (m) => { caixa.push(m); });

  try {
    const reg = await postJson(base, '/auth/registrar', {
      email, senha: 'senha1234', termosVersao: '2026-09-24',
    });
    assert.equal(reg.status, 201);
    const login = await postJson(base, '/auth/login', { email, senha: 'senha1234' });
    assert.equal(login.status, 200);
    const aparelhoA = await login.json() as { refreshToken: string };

    // Sem conta responde igual e não manda nada.
    const semConta = await postJson(base, '/auth/recuperar', {
      email: `ninguem.${Date.now()}@teste.local`,
    });
    assert.equal(semConta.status, 200);
    const corpoSemConta = await semConta.json() as { mensagem: string };
    assert.ok(corpoSemConta.mensagem);

    const pedido = await postJson(base, '/auth/recuperar', { email });
    assert.equal(pedido.status, 200);
    const corpoPedido = await pedido.json() as { mensagem: string };
    assert.equal(corpoPedido.mensagem, corpoSemConta.mensagem);
    const codigo = await esperarCodigo(caixa, email);
    assert.equal(soCodigos(caixa).length, 1);
    assert.equal(soCodigos(caixa)[0].para, email);

    const extra = await postJson(base, '/auth/redefinir', {
      email, codigo, senhaNova: 'senha5678', senhaAtual: 'senha1234',
    });
    assert.equal(extra.status, 400);

    const errado = await postJson(base, '/auth/redefinir', {
      email, codigo: codigo === '000000' ? '000001' : '000000', senhaNova: 'senha5678',
    });
    assert.equal(errado.status, 401);
    const corpoErrado = await errado.json() as { erro: string };
    assert.equal(corpoErrado.erro, 'Código inválido ou vencido.');

    const redefinir = await postJson(base, '/auth/redefinir', {
      email, codigo, senhaNova: 'senha5678',
    });
    assert.equal(redefinir.status, 200);
    const nova = await redefinir.json() as {
      mensagem: string; token: string; refreshToken: string; expiresIn: number;
      email: string; id: number; termosVersao: string | null;
    };
    assert.ok(nova.token);
    // Celular novo depois de esquecer a senha: o app sabe que o aceite já existe.
    assert.equal(nova.termosVersao, '2026-09-24');
    assert.ok(nova.refreshToken);
    assert.equal(nova.expiresIn, 900);
    assert.equal(nova.email, email);
    assert.ok(Number.isInteger(nova.id));

    const deNovo = await postJson(base, '/auth/redefinir', {
      email, codigo, senhaNova: 'senha9999',
    });
    assert.equal(deNovo.status, 401);

    const loginAntiga = await postJson(base, '/auth/login', { email, senha: 'senha1234' });
    assert.equal(loginAntiga.status, 401);
    const loginNova = await postJson(base, '/auth/login', { email, senha: 'senha5678' });
    assert.equal(loginNova.status, 200);

    const refreshVelho = await postJson(base, '/auth/refresh', {
      refreshToken: aparelhoA.refreshToken,
    });
    assert.equal(refreshVelho.status, 401);
    const refreshNovo = await postJson(base, '/auth/refresh', {
      refreshToken: nova.refreshToken,
    });
    assert.equal(refreshNovo.status, 200);

    const del = await fetch(`${base}/auth/conta`, {
      method: 'DELETE', headers: { authorization: `Bearer ${nova.token}` },
    });
    assert.equal(del.status, 200);
  } finally {
    usarTransporte(null);
    await new Promise<void>((resolve) => server.close(() => resolve()));
  }
});

test('código errado 5 vezes esgota; código novo invalida o anterior', async (t) => {
  if (!await bancoPronto(t)) return;
  const server = app.listen(0);
  const address = server.address();
  const port = typeof address === 'object' && address ? address.port : 0;
  const base = `http://127.0.0.1:${port}`;
  const email = `tentativas.${Date.now()}@teste.local`;
  const caixa: Mensagem[] = [];
  usarTransporte(async (m) => { caixa.push(m); });

  try {
    await postJson(base, '/auth/registrar', { email, senha: 'senha1234' });
    assert.equal((await postJson(base, '/auth/recuperar', { email })).status, 200);
    const primeiro = await esperarCodigo(caixa, email);
    const errado = primeiro === '000000' ? '000001' : '000000';

    for (let i = 0; i < 5; i += 1) {
      const tentativa = await postJson(base, '/auth/redefinir', {
        email, codigo: errado, senhaNova: 'senha5678',
      });
      assert.equal(tentativa.status, 401);
    }
    const esgotado = await postJson(base, '/auth/redefinir', {
      email, codigo: primeiro, senhaNova: 'senha5678',
    });
    assert.equal(esgotado.status, 401);

    // Pede outro: o anterior deixa de valer mesmo que ainda tivesse tentativas.
    caixa.length = 0;
    assert.equal((await postJson(base, '/auth/recuperar', { email })).status, 200);
    const segundo = await esperarCodigo(caixa, email);
    assert.notEqual(segundo, undefined);
    const anterior = await postJson(base, '/auth/redefinir', {
      email, codigo: primeiro, senhaNova: 'senha5678',
    });
    assert.equal(anterior.status, 401);

    const ok = await postJson(base, '/auth/redefinir', {
      email, codigo: segundo, senhaNova: 'senha5678',
    });
    assert.equal(ok.status, 200);
    const sessao = await ok.json() as { token: string };
    const del = await fetch(`${base}/auth/conta`, {
      method: 'DELETE', headers: { authorization: `Bearer ${sessao.token}` },
    });
    assert.equal(del.status, 200);
  } finally {
    usarTransporte(null);
    await new Promise<void>((resolve) => server.close(() => resolve()));
  }
});

test('quarto código na mesma hora responde 429', async (t) => {
  if (!await bancoPronto(t)) return;
  const server = app.listen(0);
  const address = server.address();
  const port = typeof address === 'object' && address ? address.port : 0;
  const base = `http://127.0.0.1:${port}`;
  const email = `limite.${Date.now()}@teste.local`;
  const caixa: Mensagem[] = [];
  usarTransporte(async (m) => { caixa.push(m); });

  try {
    await postJson(base, '/auth/registrar', { email, senha: 'senha1234' });
    for (let i = 0; i < 3; i += 1) {
      const pedido = await postJson(base, '/auth/recuperar', { email });
      assert.equal(pedido.status, 200);
    }
    const quarto = await postJson(base, '/auth/recuperar', { email });
    assert.equal(quarto.status, 429);
    const corpo = await quarto.json() as { erro: string };
    assert.ok(corpo.erro);

    // Os três chegaram; só o último vale.
    for (let i = 0; i < 100 && soCodigos(caixa).length < 3; i += 1) {
      await new Promise((resolve) => setTimeout(resolve, 20));
    }
    assert.equal(soCodigos(caixa).length, 3);
    const codigos = soCodigos(caixa).map((m) => /\b(\d{6})\b/.exec(m.texto)?.[1]);
    const usaCodigo = (codigo: string | undefined) => postJson(base, '/auth/redefinir', {
      email, codigo, senhaNova: 'senha5678',
    });
    assert.equal((await usaCodigo(codigos[0])).status, 401);
    assert.equal((await usaCodigo(codigos[1])).status, 401);
    const ultimo = await usaCodigo(codigos[2]);
    assert.equal(ultimo.status, 200);

    const sessao = await ultimo.json() as { token: string };
    const del = await fetch(`${base}/auth/conta`, {
      method: 'DELETE', headers: { authorization: `Bearer ${sessao.token}` },
    });
    assert.equal(del.status, 200);
  } finally {
    usarTransporte(null);
    await new Promise<void>((resolve) => server.close(() => resolve()));
  }
});

test('pedidos simultâneos respeitam os 3 códigos por hora', async (t) => {
  if (!await bancoPronto(t)) return;
  const server = app.listen(0);
  const address = server.address();
  const port = typeof address === 'object' && address ? address.port : 0;
  const base = `http://127.0.0.1:${port}`;
  const email = `rajada.${Date.now()}@teste.local`;
  const caixa: Mensagem[] = [];
  usarTransporte(async (m) => { caixa.push(m); });

  try {
    assert.equal((await postJson(base, '/auth/registrar', { email, senha: 'senha1234' })).status, 201);

    // Cinco de uma vez: a contagem dentro da transação deixa passar só três.
    const respostas = await Promise.all(
      Array.from({ length: 5 }, () => postJson(base, '/auth/recuperar', { email })),
    );
    const status = respostas.map((r) => r.status).sort((a, b) => a - b);
    assert.deepEqual(status, [200, 200, 200, 429, 429]);

    const [rows] = await getPool().execute<import('mysql2').RowDataPacket[]>(
      `SELECT COUNT(*) AS total FROM recuperacoes_senha r
         JOIN usuarios u ON u.id = r.usuario_id WHERE u.email = ?`,
      [email],
    );
    assert.equal(Number(rows[0].total), 3);

    for (let i = 0; i < 100 && soCodigos(caixa).length < 3; i += 1) {
      await new Promise((resolve) => setTimeout(resolve, 20));
    }
    await new Promise((resolve) => setTimeout(resolve, 50));
    assert.equal(soCodigos(caixa).length, 3);

    const sexto = await postJson(base, '/auth/recuperar', { email });
    assert.equal(sexto.status, 429);
  } finally {
    usarTransporte(null);
    await getPool().execute('DELETE FROM usuarios WHERE email = ?', [email]);
    await new Promise<void>((resolve) => server.close(() => resolve()));
  }
});

test('produção sem chave de e-mail responde 503 em /auth/recuperar', async (t) => {
  if (!await bancoPronto(t)) return;
  const server = app.listen(0);
  const address = server.address();
  const port = typeof address === 'object' && address ? address.port : 0;
  const base = `http://127.0.0.1:${port}`;
  const ambiente = process.env.NODE_ENV;
  const chave = process.env.RESEND_API_KEY;

  try {
    process.env.NODE_ENV = 'production';
    delete process.env.RESEND_API_KEY;
    usarTransporte(null);
    const resposta = await postJson(base, '/auth/recuperar', {
      email: `producao.${Date.now()}@teste.local`,
    });
    assert.equal(resposta.status, 503);
    const corpo = await resposta.json() as { erro: string };
    assert.equal(corpo.erro, 'Recuperação de senha não está ligada neste servidor.');
  } finally {
    process.env.NODE_ENV = ambiente;
    if (chave !== undefined) process.env.RESEND_API_KEY = chave;
    await new Promise<void>((resolve) => server.close(() => resolve()));
  }
});

test('limpeza apaga só recuperações vencidas há mais de um dia', async (t) => {
  if (!await bancoPronto(t)) return;
  const email = `limpeza.codigo.${Date.now()}@teste.local`;
  const pool = getPool();
  const [u] = await pool.execute<import('mysql2').ResultSetHeader>(
    'INSERT INTO usuarios (email, senha) VALUES (?, ?)',
    [email, 'x'],
  );
  try {
    await pool.execute(
      `INSERT INTO recuperacoes_senha (usuario_id, codigo_hash, expira_em) VALUES
         (?, 'velha', UTC_TIMESTAMP() - INTERVAL 2 DAY),
         (?, 'recente', UTC_TIMESTAMP() - INTERVAL 1 HOUR),
         (?, 'viva', UTC_TIMESTAMP() + INTERVAL 15 MINUTE)`,
      [u.insertId, u.insertId, u.insertId],
    );
    await apagarRecuperacoesVencidas();
    const [rows] = await pool.execute<import('mysql2').RowDataPacket[]>(
      'SELECT codigo_hash FROM recuperacoes_senha WHERE usuario_id = ? ORDER BY id',
      [u.insertId],
    );
    assert.deepEqual(rows.map((r) => r.codigo_hash), ['recente', 'viva']);
  } finally {
    await pool.execute('DELETE FROM usuarios WHERE id = ?', [u.insertId]);
  }
});

test('crash com contexto vai para eventos_cliente; campo extra é recusado', async (t) => {
  if (!await bancoPronto(t)) return;
  const server = app.listen(0);
  const address = server.address();
  const port = typeof address === 'object' && address ? address.port : 0;
  const base = `http://127.0.0.1:${port}`;
  const json = { 'content-type': 'application/json' };
  const marca = `pilha-${Date.now()}`;

  try {
    const ok = await fetch(`${base}/monitor/evento`, {
      method: 'POST',
      headers: json,
      body: JSON.stringify({
        tipo: 'flutter_zone',
        mensagem: 'Null check operator used on a null value',
        ambiente: 'production',
        versaoApp: '1.2.1+6',
        plataforma: 'android 14',
        pilha: `#0 ${marca}
#1 outra linha`,
      }),
    });
    assert.equal(ok.status, 200);

    const [rows] = await getPool().execute<import('mysql2').RowDataPacket[]>(
      'SELECT tipo, versao_app, plataforma, pilha FROM eventos_cliente WHERE pilha LIKE ?',
      [`%${marca}%`],
    );
    assert.equal(rows.length, 1);
    assert.equal(rows[0].tipo, 'flutter_zone');
    assert.equal(rows[0].versao_app, '1.2.1+6');
    assert.equal(rows[0].plataforma, 'android 14');

    const extra = await fetch(`${base}/monitor/evento`, {
      method: 'POST',
      headers: json,
      body: JSON.stringify({ tipo: 'flutter_error', mensagem: 'x', email: 'a@b.c' }),
    });
    assert.equal(extra.status, 400);

    // Recusa do convite de conta: mesmo caminho, sem nada que ligue ao piloto.
    const recusa = await fetch(`${base}/monitor/evento`, {
      method: 'POST',
      headers: json,
      body: JSON.stringify({
        tipo: 'conta_recusada',
        mensagem: 'não quero dar meu e-mail',
        ambiente: 'production',
        versaoApp: '1.3.0+7',
        pilha: `motivo-${marca}`,
      }),
    });
    assert.equal(recusa.status, 200);
    const [recusas] = await getPool().execute<import('mysql2').RowDataPacket[]>(
      'SELECT tipo, mensagem FROM eventos_cliente WHERE pilha = ?',
      [`motivo-${marca}`],
    );
    assert.equal(recusas.length, 1);
    assert.equal(recusas[0].tipo, 'conta_recusada');
    assert.equal(recusas[0].mensagem, 'não quero dar meu e-mail');
  } finally {
    await getPool().execute('DELETE FROM eventos_cliente WHERE pilha LIKE ?', [`%${marca}%`]);
    await new Promise<void>((resolve) => server.close(() => resolve()));
  }
});

