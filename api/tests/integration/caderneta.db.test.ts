import { after, test, type TestContext } from 'node:test';
import assert from 'node:assert/strict';
import type { RowDataPacket } from 'mysql2';
import app from '../../src/app';
import { fecharPool, getPool, pingBanco } from '../../src/shared/database/pool';
import { migrar } from '../../src/shared/database/migrar';

// Caderneta na nuvem e aceite dos termos (ADR 0038).

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

const subir = () => {
  const server = app.listen(0);
  const address = server.address();
  const port = typeof address === 'object' && address ? address.port : 0;
  return {
    base: `http://127.0.0.1:${port}`,
    fechar: () => new Promise<void>((resolve) => server.close(() => resolve())),
  };
};

const pedir = (
  base: string,
  metodo: string,
  rota: string,
  opcoes: { token?: string; corpo?: unknown } = {},
) => fetch(`${base}${rota}`, {
  method: metodo,
  headers: {
    'content-type': 'application/json',
    ...(opcoes.token ? { authorization: `Bearer ${opcoes.token}` } : {}),
  },
  body: opcoes.corpo === undefined ? undefined : JSON.stringify(opcoes.corpo),
});

let sequencia = 0;
const emailNovo = (prefixo: string) =>
  `${prefixo}.${Date.now()}.${(sequencia += 1)}@teste.local`;

/** Cadastra e entra. Devolve o token, o id e o e-mail. */
const novaConta = async (base: string, prefixo: string) => {
  const email = emailNovo(prefixo);
  const reg = await pedir(base, 'POST', '/auth/registrar', {
    corpo: { email, senha: 'senha1234' },
  });
  assert.equal(reg.status, 201);
  const login = await pedir(base, 'POST', '/auth/login', {
    corpo: { email, senha: 'senha1234' },
  });
  assert.equal(login.status, 200);
  const corpo = await login.json() as { token: string; id: number };
  return { email, token: corpo.token, id: corpo.id };
};

const apagarContas = async (...emails: string[]) => {
  for (const email of emails) {
    await getPool().execute('DELETE FROM usuarios WHERE email = ?', [email]);
  }
};

const conteudo = (abastecimentos = 1) => ({
  v: 1,
  abastecimentos: Array.from({ length: abastecimentos }, (_, i) => ({
    id: i + 1,
    litros: 10 + i,
    km: 1000 + i * 100,
  })),
  servicos: [{ id: 1, tipo: 'oleo', km: 12000 }],
  pins: [{ id: 1, nome: 'Posto do Zé', lat: -20.75, lng: -42.88 }],
  extra: '{"kmOleo":12000,"cnhProxima":"2031-05-10"}',
  precoGasolina: '6.29',
  precoAlcool: '4.39',
  psi: { dianteiro: 25, traseiro: 29 },
});

type CadernetaResposta = { conteudo: unknown; atualizadoEm: string };

test('caderneta exige token em todas as rotas', async (t) => {
  if (!await bancoPronto(t)) return;
  const s = subir();
  try {
    assert.equal((await pedir(s.base, 'GET', '/caderneta')).status, 401);
    assert.equal((await pedir(s.base, 'PUT', '/caderneta', {
      corpo: { conteudo: conteudo(), baseAtualizadoEm: null },
    })).status, 401);
    assert.equal((await pedir(s.base, 'DELETE', '/caderneta')).status, 401);
  } finally {
    await s.fechar();
  }
});

test('guarda, devolve igual, e o banco só tem bytes cifrados', async (t) => {
  if (!await bancoPronto(t)) return;
  const s = subir();
  const conta = await novaConta(s.base, 'nuvem');
  try {
    const vazio = await pedir(s.base, 'GET', '/caderneta', { token: conta.token });
    assert.equal(vazio.status, 404, 'sem caderneta ainda');

    const envio = await pedir(s.base, 'PUT', '/caderneta', {
      token: conta.token,
      corpo: { conteudo: conteudo(3), baseAtualizadoEm: null },
    });
    assert.equal(envio.status, 200);
    const { atualizadoEm } = await envio.json() as { atualizadoEm: string };
    assert.ok(!Number.isNaN(Date.parse(atualizadoEm)));

    const lida = await pedir(s.base, 'GET', '/caderneta', { token: conta.token });
    assert.equal(lida.status, 200);
    const corpo = await lida.json() as CadernetaResposta;
    assert.deepEqual(corpo.conteudo, conteudo(3));
    assert.equal(corpo.atualizadoEm, atualizadoEm);

    const [rows] = await getPool().execute<RowDataPacket[]>(
      'SELECT conteudo, versao_chave, tamanho FROM cadernetas_nuvem WHERE usuario_id = ?',
      [conta.id],
    );
    const bruto = rows[0].conteudo as Buffer;
    assert.ok(!bruto.includes(Buffer.from('Posto do Z')), 'nome do pino não aparece');
    assert.ok(!bruto.includes(Buffer.from('abastecimentos')), 'nome de campo não aparece');
    assert.ok(!bruto.includes(Buffer.from('cnhProxima')), 'CNH não aparece');
    assert.equal(Number(rows[0].versao_chave), 1);
    assert.equal(Number(rows[0].tamanho), Buffer.byteLength(JSON.stringify(corpo.conteudo)));
  } finally {
    await apagarContas(conta.email);
    await s.fechar();
  }
});

test('grava com o carimbo certo; com carimbo velho responde 409 e não grava', async (t) => {
  if (!await bancoPronto(t)) return;
  const s = subir();
  const conta = await novaConta(s.base, 'conflito');
  try {
    const primeiro = await pedir(s.base, 'PUT', '/caderneta', {
      token: conta.token,
      corpo: { conteudo: conteudo(1), baseAtualizadoEm: null },
    });
    const t1 = (await primeiro.json() as { atualizadoEm: string }).atualizadoEm;

    const segundo = await pedir(s.base, 'PUT', '/caderneta', {
      token: conta.token,
      corpo: { conteudo: conteudo(2), baseAtualizadoEm: t1 },
    });
    assert.equal(segundo.status, 200);
    const t2 = (await segundo.json() as { atualizadoEm: string }).atualizadoEm;
    assert.ok(Date.parse(t2) > Date.parse(t1), 'o carimbo novo é sempre maior');

    // Outro aparelho, que ainda conhece só o t1, tenta gravar por cima.
    const velho = await pedir(s.base, 'PUT', '/caderneta', {
      token: conta.token,
      corpo: { conteudo: conteudo(9), baseAtualizadoEm: t1 },
    });
    assert.equal(velho.status, 409);
    const erro = await velho.json() as { detalhes: { atualizadoEm: string } };
    assert.equal(erro.detalhes.atualizadoEm, t2, 'devolve o carimbo atual');

    // E sem carimbo nenhum, com caderneta já existindo, também não passa.
    const semBase = await pedir(s.base, 'PUT', '/caderneta', {
      token: conta.token,
      corpo: { conteudo: conteudo(9), baseAtualizadoEm: null },
    });
    assert.equal(semBase.status, 409);

    const lida = await pedir(s.base, 'GET', '/caderneta', { token: conta.token });
    const corpo = await lida.json() as CadernetaResposta;
    assert.deepEqual(corpo.conteudo, conteudo(2), 'nada foi escrito por cima');
  } finally {
    await apagarContas(conta.email);
    await s.fechar();
  }
});

test('dois aparelhos mandando a primeira caderneta juntos: um grava, o outro recebe 409', async (t) => {
  if (!await bancoPronto(t)) return;
  const s = subir();
  const conta = await novaConta(s.base, 'simultaneo');
  try {
    const respostas = await Promise.all([1, 2].map((n) => pedir(s.base, 'PUT', '/caderneta', {
      token: conta.token,
      corpo: { conteudo: conteudo(n), baseAtualizadoEm: null },
    })));
    const status = respostas.map((r) => r.status).sort();
    assert.deepEqual(status, [200, 409]);

    const vencedora = respostas.find((r) => r.status === 200)!;
    const { atualizadoEm } = await vencedora.json() as { atualizadoEm: string };
    const lida = await pedir(s.base, 'GET', '/caderneta', { token: conta.token });
    assert.equal((await lida.json() as CadernetaResposta).atualizadoEm, atualizadoEm);
  } finally {
    await apagarContas(conta.email);
    await s.fechar();
  }
});

test('contrato estrito: foto, chave a mais, chave faltando e versão errada são recusados', async (t) => {
  if (!await bancoPronto(t)) return;
  const s = subir();
  // Uma conta por caso: o limite de envios vem antes da validação, e 7 envios
  // na mesma conta passariam dos 5 do teste.
  const emails: string[] = [];
  const enviar = async (corpo: unknown) => {
    const conta = await novaConta(s.base, 'estrito');
    emails.push(conta.email);
    return pedir(s.base, 'PUT', '/caderneta', { token: conta.token, corpo });
  };
  try {
    const { pins: _pins, ...semPins } = conteudo();
    const recusados: Array<[string, unknown]> = [
      ['foto', { conteudo: { ...conteudo(), foto: 'AAAA' }, baseAtualizadoEm: null }],
      ['ficha', { conteudo: { ...conteudo(), ficha: '{}' }, baseAtualizadoEm: null }],
      ['sem pins', { conteudo: semPins, baseAtualizadoEm: null }],
      ['versão 2', { conteudo: { ...conteudo(), v: 2 }, baseAtualizadoEm: null }],
      ['campo a mais no corpo', { conteudo: conteudo(), baseAtualizadoEm: null, x: 1 }],
      ['carimbo malformado', { conteudo: conteudo(), baseAtualizadoEm: 'ontem' }],
      ['PSI absurdo', { conteudo: { ...conteudo(), psi: { dianteiro: 999, traseiro: 29 } }, baseAtualizadoEm: null }],
    ];
    for (const [nome, corpo] of recusados) {
      assert.equal((await enviar(corpo)).status, 400, nome);
    }
  } finally {
    await apagarContas(...emails);
    await s.fechar();
  }
});

test('caderneta acima de 20 KB passa; acima de 512 KB é recusada', async (t) => {
  if (!await bancoPronto(t)) return;
  const s = subir();
  const conta = await novaConta(s.base, 'tamanho');
  try {
    const media = conteudo(600);
    assert.ok(JSON.stringify(media).length > 20 * 1024, 'passa do limite padrão');
    const aceita = await pedir(s.base, 'PUT', '/caderneta', {
      token: conta.token,
      corpo: { conteudo: media, baseAtualizadoEm: null },
    });
    assert.equal(aceita.status, 200, 'o limite próprio da caderneta vale');

    const enorme = { ...conteudo(), servicos: Array.from({ length: 3000 }, (_, i) => ({ id: i, nota: 'x'.repeat(200) })) };
    assert.ok(JSON.stringify(enorme).length > 512 * 1024);
    const recusada = await pedir(s.base, 'PUT', '/caderneta', {
      token: conta.token,
      corpo: { conteudo: enorme, baseAtualizadoEm: null },
    });
    assert.equal(recusada.status, 413);
  } finally {
    await apagarContas(conta.email);
    await s.fechar();
  }
});

test('o limite de 20 KB continua valendo nas outras rotas', async (t) => {
  if (!await bancoPronto(t)) return;
  const s = subir();
  try {
    const grande = await pedir(s.base, 'POST', '/auth/login', {
      corpo: { email: 'a@teste.local', senha: 'x'.repeat(25 * 1024) },
    });
    assert.equal(grande.status, 413);
  } finally {
    await s.fechar();
  }
});

test('DELETE apaga, e o GET volta a dar 404', async (t) => {
  if (!await bancoPronto(t)) return;
  const s = subir();
  const conta = await novaConta(s.base, 'desligar');
  try {
    await pedir(s.base, 'PUT', '/caderneta', {
      token: conta.token,
      corpo: { conteudo: conteudo(), baseAtualizadoEm: null },
    });
    const apagou = await pedir(s.base, 'DELETE', '/caderneta', { token: conta.token });
    assert.equal(apagou.status, 204);
    assert.equal((await pedir(s.base, 'GET', '/caderneta', { token: conta.token })).status, 404);
    // Apagar de novo não é erro.
    assert.equal((await pedir(s.base, 'DELETE', '/caderneta', { token: conta.token })).status, 204);
  } finally {
    await apagarContas(conta.email);
    await s.fechar();
  }
});

test('excluir a conta leva a caderneta da nuvem junto', async (t) => {
  if (!await bancoPronto(t)) return;
  const s = subir();
  const conta = await novaConta(s.base, 'excluir');
  try {
    await pedir(s.base, 'PUT', '/caderneta', {
      token: conta.token,
      corpo: { conteudo: conteudo(), baseAtualizadoEm: null },
    });
    const excluiu = await pedir(s.base, 'DELETE', '/auth/conta', { token: conta.token });
    assert.ok(excluiu.status === 200 || excluiu.status === 204);
    const [rows] = await getPool().execute<RowDataPacket[]>(
      'SELECT COUNT(*) AS total FROM cadernetas_nuvem WHERE usuario_id = ?',
      [conta.id],
    );
    assert.equal(Number(rows[0].total), 0);
  } finally {
    await apagarContas(conta.email);
    await s.fechar();
  }
});

test('uma conta não lê a caderneta de outra, nem copiando a cifra no banco', async (t) => {
  if (!await bancoPronto(t)) return;
  const s = subir();
  const a = await novaConta(s.base, 'dona');
  const b = await novaConta(s.base, 'outra');
  try {
    await pedir(s.base, 'PUT', '/caderneta', {
      token: a.token,
      corpo: { conteudo: conteudo(), baseAtualizadoEm: null },
    });
    assert.equal((await pedir(s.base, 'GET', '/caderneta', { token: b.token })).status, 404);

    // Alguém com escrita no banco copia a cifra da A para a linha da B.
    await getPool().execute(
      `INSERT INTO cadernetas_nuvem (usuario_id, conteudo, versao_chave, tamanho, atualizado_em_ms)
       SELECT ?, conteudo, versao_chave, tamanho, atualizado_em_ms
         FROM cadernetas_nuvem WHERE usuario_id = ?`,
      [b.id, a.id],
    );
    const copia = await pedir(s.base, 'GET', '/caderneta', { token: b.token });
    assert.equal(copia.status, 500, 'a cifra está amarrada à conta da A');
    const corpo = await copia.json() as { erro: string; conteudo?: unknown };
    assert.equal(corpo.conteudo, undefined, 'nada da A vaza');
  } finally {
    await apagarContas(a.email, b.email);
    await s.fechar();
  }
});

test('sem a chave no ambiente, a caderneta responde 503 e o login segue', async (t) => {
  if (!await bancoPronto(t)) return;
  const s = subir();
  const conta = await novaConta(s.base, 'semchave');
  const antes = process.env.CADERNETA_CHAVE;
  try {
    delete process.env.CADERNETA_CHAVE;
    assert.equal((await pedir(s.base, 'GET', '/caderneta', { token: conta.token })).status, 503);
    assert.equal((await pedir(s.base, 'PUT', '/caderneta', {
      token: conta.token,
      corpo: { conteudo: conteudo(), baseAtualizadoEm: null },
    })).status, 503);
    const login = await pedir(s.base, 'POST', '/auth/login', {
      corpo: { email: conta.email, senha: 'senha1234' },
    });
    assert.equal(login.status, 200, 'o resto da API não depende da chave');
  } finally {
    process.env.CADERNETA_CHAVE = antes;
    await apagarContas(conta.email);
    await s.fechar();
  }
});

test('o limite de envios é por conta', async (t) => {
  if (!await bancoPronto(t)) return;
  const s = subir();
  const insistente = await novaConta(s.base, 'limite');
  const vizinha = await novaConta(s.base, 'vizinha');
  const envio = (token: string) => pedir(s.base, 'PUT', '/caderneta', {
    token,
    corpo: { conteudo: conteudo(), baseAtualizadoEm: null },
  });
  try {
    // No teste o limite é 5 (setup-env). Os 409 também contam: quem insiste
    // gasta a cota do mesmo jeito.
    for (let i = 0; i < 5; i += 1) {
      assert.notEqual((await envio(insistente.token)).status, 429, `envio ${i + 1}`);
    }
    assert.equal((await envio(insistente.token)).status, 429, 'o sexto passa do limite');
    assert.equal((await envio(vizinha.token)).status, 200, 'a outra conta não é afetada');
  } finally {
    await apagarContas(insistente.email, vizinha.email);
    await s.fechar();
  }
});

// Aceite dos termos.

const termosNoBanco = async (email: string) => {
  const [rows] = await getPool().execute<RowDataPacket[]>(
    'SELECT termos_versao, termos_aceitos_em FROM usuarios WHERE email = ?',
    [email],
  );
  return rows[0] as { termos_versao: string | null; termos_aceitos_em: Date | null };
};

test('cadastro com a versão dos termos grava versão e data, e o login devolve', async (t) => {
  if (!await bancoPronto(t)) return;
  const s = subir();
  const email = emailNovo('termos');
  try {
    const reg = await pedir(s.base, 'POST', '/auth/registrar', {
      corpo: { email, senha: 'senha1234', termosVersao: '2026-09-24' },
    });
    assert.equal(reg.status, 201);
    const gravado = await termosNoBanco(email);
    assert.equal(gravado.termos_versao, '2026-09-24');
    assert.ok(gravado.termos_aceitos_em, 'a data do aceite fica registrada');

    const login = await pedir(s.base, 'POST', '/auth/login', {
      corpo: { email, senha: 'senha1234' },
    });
    const corpo = await login.json() as { termosVersao: string | null };
    assert.equal(corpo.termosVersao, '2026-09-24');
  } finally {
    await apagarContas(email);
    await s.fechar();
  }
});

test('cadastro sem a versão, como o APK antigo, continua dando 201 e grava nulo', async (t) => {
  if (!await bancoPronto(t)) return;
  const s = subir();
  const email = emailNovo('apkantigo');
  try {
    const reg = await pedir(s.base, 'POST', '/auth/registrar', {
      corpo: { email, senha: 'senha1234' },
    });
    assert.equal(reg.status, 201);
    const gravado = await termosNoBanco(email);
    assert.equal(gravado.termos_versao, null);
    assert.equal(gravado.termos_aceitos_em, null);

    const login = await pedir(s.base, 'POST', '/auth/login', {
      corpo: { email, senha: 'senha1234' },
    });
    const corpo = await login.json() as { termosVersao: string | null };
    assert.equal(corpo.termosVersao, null, 'o app novo sabe que precisa pedir o aceite');
  } finally {
    await apagarContas(email);
    await s.fechar();
  }
});

test('versão dos termos malformada no cadastro é recusada', async (t) => {
  if (!await bancoPronto(t)) return;
  const s = subir();
  const email = emailNovo('termosruins');
  try {
    const reg = await pedir(s.base, 'POST', '/auth/registrar', {
      corpo: { email, senha: 'senha1234', termosVersao: 'aceito' },
    });
    assert.equal(reg.status, 400);
  } finally {
    await apagarContas(email);
    await s.fechar();
  }
});

test('quem já tem conta aceita os termos pela rota própria', async (t) => {
  if (!await bancoPronto(t)) return;
  const s = subir();
  const conta = await novaConta(s.base, 'aceitedepois');
  try {
    assert.equal((await pedir(s.base, 'POST', '/auth/termos', {
      corpo: { versao: '2026-09-24' },
    })).status, 401, 'exige token');

    assert.equal((await pedir(s.base, 'POST', '/auth/termos', {
      token: conta.token,
      corpo: { versao: '2026-09-24', extra: true },
    })).status, 400, 'contrato estrito');

    assert.equal((await pedir(s.base, 'POST', '/auth/termos', {
      token: conta.token,
      corpo: { versao: 'hoje' },
    })).status, 400, 'versão malformada');

    const aceite = await pedir(s.base, 'POST', '/auth/termos', {
      token: conta.token,
      corpo: { versao: '2026-09-24' },
    });
    assert.equal(aceite.status, 200);
    assert.deepEqual(await aceite.json(), { termosVersao: '2026-09-24' });
    const gravado = await termosNoBanco(conta.email);
    assert.equal(gravado.termos_versao, '2026-09-24');
    assert.ok(gravado.termos_aceitos_em);
  } finally {
    await apagarContas(conta.email);
    await s.fechar();
  }
});
