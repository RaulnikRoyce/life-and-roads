import { test } from 'node:test';
import assert from 'node:assert/strict';
import { senhaSchema } from '../../src/modules/auth/auth.schema';

test('troca de senha válida passa', () => {
  const r = senhaSchema.safeParse({
    senhaAtual: 'senha1234',
    senhaNova: 'senha5678',
  });
  assert.equal(r.success, true);
});

test('senha nova igual à atual é recusada', () => {
  const r = senhaSchema.safeParse({
    senhaAtual: 'senha1234',
    senhaNova: 'senha1234',
  });
  assert.equal(r.success, false);
});

test('senha curta é recusada', () => {
  const r = senhaSchema.safeParse({
    senhaAtual: 'senha1234',
    senhaNova: 'curta',
  });
  assert.equal(r.success, false);
});

test('campo extra é recusado', () => {
  const r = senhaSchema.safeParse({
    senhaAtual: 'senha1234',
    senhaNova: 'senha5678',
    email: 'x@y.z',
  });
  assert.equal(r.success, false);
});
