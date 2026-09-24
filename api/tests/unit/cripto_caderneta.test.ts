import { test } from 'node:test';
import assert from 'node:assert/strict';
import { randomBytes } from 'crypto';
import { chaveDaCaderneta, cifrar, decifrar } from '../../src/shared/cripto/caderneta';

const chave = randomBytes(32);
const texto = JSON.stringify({ v: 1, abastecimentos: [{ litros: 12.4 }], pins: [] });

test('cifra e abre de volta com a mesma chave e a mesma conta', () => {
  const cifrado = cifrar(texto, chave, 42);
  assert.equal(decifrar(cifrado, chave, 42), texto);
});

test('o cifrado não carrega o texto aberto', () => {
  const cifrado = cifrar(texto, chave, 42);
  assert.ok(!cifrado.includes(Buffer.from('abastecimentos')));
  assert.ok(!cifrado.includes(Buffer.from('litros')));
});

test('cada gravação sorteia um IV novo, então o mesmo texto nunca repete', () => {
  const a = cifrar(texto, chave, 42);
  const b = cifrar(texto, chave, 42);
  assert.notDeepEqual(a, b);
});

test('outra chave não abre', () => {
  const cifrado = cifrar(texto, chave, 42);
  assert.throws(() => decifrar(cifrado, randomBytes(32), 42));
});

test('um byte mexido no banco faz a abertura falhar em vez de devolver lixo', () => {
  const cifrado = cifrar(texto, chave, 42);
  const mexido = Buffer.from(cifrado);
  mexido[mexido.length - 1] ^= 0x01;
  assert.throws(() => decifrar(mexido, chave, 42));
});

test('a cifra de uma conta não abre na linha de outra', () => {
  const cifrado = cifrar(texto, chave, 42);
  assert.throws(() => decifrar(cifrado, chave, 43));
});

test('conteúdo curto demais é recusado', () => {
  assert.throws(() => decifrar(Buffer.alloc(10), chave, 42));
});

test('chave do ambiente: ausente é null, malformada lança, certa tem 32 bytes', () => {
  const antes = process.env.CADERNETA_CHAVE;
  try {
    delete process.env.CADERNETA_CHAVE;
    assert.equal(chaveDaCaderneta(), null);

    process.env.CADERNETA_CHAVE = 'curta';
    assert.throws(() => chaveDaCaderneta());

    process.env.CADERNETA_CHAVE = Buffer.alloc(16, 1).toString('base64');
    assert.throws(() => chaveDaCaderneta(), 'chave de 16 bytes não serve');

    process.env.CADERNETA_CHAVE = randomBytes(32).toString('base64');
    assert.equal(chaveDaCaderneta()?.length, 32);
  } finally {
    if (antes === undefined) delete process.env.CADERNETA_CHAVE;
    else process.env.CADERNETA_CHAVE = antes;
  }
});
