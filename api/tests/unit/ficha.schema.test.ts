import { test } from 'node:test';
import assert from 'node:assert/strict';
import { fichaSchema } from '../../src/modules/ficha/ficha.schema';

const valida = {
  marca: 'Honda',
  modelo: 'CG 160',
  ano: 2020,
  cilindrada: 160,
  kmLitro: 42,
  kmLitroAlcool: 30,
  combustivel: 'gasolina' as const,
  kmAtual: 12000,
  tanqueLitros: 16.1,
  personalizacoes: 'baú',
};

test('ficha válida passa', () => {
  const r = fichaSchema.safeParse(valida);
  assert.equal(r.success, true);
});

test('placa extra é recusada', () => {
  const r = fichaSchema.safeParse({ ...valida, placa: 'ABC1D23' });
  assert.equal(r.success, false);
});

test('chassi extra é recusado', () => {
  const r = fichaSchema.safeParse({ ...valida, chassi: '9C2KC0810' });
  assert.equal(r.success, false);
});

test('ficha sem tanque passa', () => {
  const { tanqueLitros: _ignorado, ...semTanque } = valida;
  const r = fichaSchema.safeParse(semTanque);
  assert.equal(r.success, true);
  if (r.success) assert.equal(r.data.tanqueLitros, null);
});

test('tanque menor que 2 L é recusado', () => {
  const r = fichaSchema.safeParse({ ...valida, tanqueLitros: 1 });
  assert.equal(r.success, false);
});

test('álcool no combustível passa', () => {
  const r = fichaSchema.safeParse({ ...valida, combustivel: 'alcool' });
  assert.equal(r.success, true);
});

test('combustível estranho é recusado', () => {
  const r = fichaSchema.safeParse({ ...valida, combustivel: 'diesel' });
  assert.equal(r.success, false);
});
