import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  escaparHtml,
  htmlDoCodigo,
  textoDoCodigo,
  urlPublica,
} from '../../src/shared/email/modelo_codigo';

test('texto puro contém o código, o prazo e o aviso', () => {
  const texto = textoDoCodigo('406259');
  assert.ok(texto.includes('406259'));
  assert.ok(texto.includes('15 minutos'));
  assert.ok(texto.includes('Se não foi você'));
});

test('html contém o código, o prazo e o aviso', () => {
  const html = htmlDoCodigo('406259');
  assert.ok(html.includes('406259'));
  assert.ok(html.includes('15 minutos'));
  assert.ok(html.includes('uma única vez'));
  assert.ok(html.includes('Se não foi você'));
  assert.ok(html.includes('Sua senha continua a mesma'));
});

test('html não tem script, link clicável nem rastreio', () => {
  const html = htmlDoCodigo('406259');
  assert.ok(!/<script/i.test(html));
  assert.ok(!/<a\s/i.test(html));
  // A única imagem é a logo, servida pela própria API; nada de pixel externo.
  const imagens = html.match(/<img[^>]*src="([^"]+)"/gi) ?? [];
  assert.equal(imagens.length, 1);
  assert.ok(imagens[0].includes(`${urlPublica()}/marca/logo.png`));
  // Toda URL do e-mail sai da API. Recurso de outro domínio, como o Google
  // Fonts que havia aqui, o Gmail lê como sinal de spam.
  const urls = html.match(/https?:\/\/[^"' )]+/g) ?? [];
  for (const u of urls) {
    assert.ok(u.startsWith(urlPublica()), `url fora do domínio: ${u}`);
  }
});

test('html não busca fonte nem folha de estilo de fora', () => {
  const html = htmlDoCodigo('406259');
  assert.ok(!html.includes('fonts.googleapis'));
  assert.ok(!/@import/i.test(html));
  assert.ok(!/<link\s/i.test(html));
});

test('html usa tabelas de apresentação, o tema escuro e a fonte do app', () => {
  const html = htmlDoCodigo('406259');
  assert.ok(html.includes('role="presentation"'));
  assert.ok(html.includes('name="color-scheme" content="dark"'));
  assert.ok(html.includes('#121212'));
  assert.ok(html.includes("'Oswald'"));
});

test('urlPublica vem do ambiente sem barra no fim', () => {
  const antes = process.env.API_URL_PUBLICA;
  process.env.API_URL_PUBLICA = 'https://exemplo.test/';
  try {
    assert.equal(urlPublica(), 'https://exemplo.test');
    assert.ok(htmlDoCodigo('1').includes('https://exemplo.test/marca/logo.png'));
  } finally {
    if (antes === undefined) delete process.env.API_URL_PUBLICA;
    else process.env.API_URL_PUBLICA = antes;
  }
});

test('html escapa um código malicioso', () => {
  const html = htmlDoCodigo('<b>1</b>');
  assert.ok(!html.includes('<b>1</b>'));
  assert.ok(html.includes('&lt;b&gt;1&lt;/b&gt;'));
});

test('escaparHtml troca os cinco caracteres', () => {
  assert.equal(escaparHtml(`<a href="x" title='y'>&</a>`), '&lt;a href=&quot;x&quot; title=&#39;y&#39;&gt;&amp;&lt;/a&gt;');
});
