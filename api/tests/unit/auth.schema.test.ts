import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  recuperarSchema,
  redefinirSchema,
  senhaSchema,
} from '../../src/modules/auth/auth.schema';

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

test('recuperar normaliza o e-mail', () => {
  const r = recuperarSchema.safeParse({ email: '  Piloto@Teste.Local ' });
  assert.equal(r.success, true);
  assert.equal(r.data?.email, 'piloto@teste.local');
});

test('recuperar com e-mail inválido ou campo extra é recusado', () => {
  assert.equal(recuperarSchema.safeParse({ email: 'sem-arroba' }).success, false);
  assert.equal(
    recuperarSchema.safeParse({ email: 'piloto@teste.local', codigo: '123456' }).success,
    false,
  );
});

test('redefinir válido passa', () => {
  const r = redefinirSchema.safeParse({
    email: 'piloto@teste.local',
    codigo: '012345',
    senhaNova: 'senha5678',
  });
  assert.equal(r.success, true);
  assert.equal(r.data?.codigo, '012345');
});

test('código com letra é recusado', () => {
  const r = redefinirSchema.safeParse({
    email: 'piloto@teste.local',
    codigo: '12345a',
    senhaNova: 'senha5678',
  });
  assert.equal(r.success, false);
});

test('código com 5 dígitos é recusado', () => {
  const r = redefinirSchema.safeParse({
    email: 'piloto@teste.local',
    codigo: '12345',
    senhaNova: 'senha5678',
  });
  assert.equal(r.success, false);
});

test('redefinir com senha curta é recusado', () => {
  const r = redefinirSchema.safeParse({
    email: 'piloto@teste.local',
    codigo: '123456',
    senhaNova: 'curta',
  });
  assert.equal(r.success, false);
});

test('redefinir com campo extra é recusado', () => {
  const r = redefinirSchema.safeParse({
    email: 'piloto@teste.local',
    codigo: '123456',
    senhaNova: 'senha5678',
    senhaAtual: 'senha1234',
  });
  assert.equal(r.success, false);
});
