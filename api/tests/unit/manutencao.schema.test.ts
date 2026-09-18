import { test } from 'node:test';
import assert from 'node:assert/strict';
import { manutencaoSchema } from '../../src/modules/manutencao/manutencao.schema';

const valida = {
  oleoUltima: '2026-01-10',
  oleoProxima: '2026-07-10',
  revisaoUltima: '2026-02-01',
  pneusUltima: '2025-12-01',
  pneusProxima: '2026-12-01',
  ipvaProxima: '2026-03-31',
  seguroProxima: '2026-08-01',
  licenciamentoProxima: '2026-04-30',
};

test('manutenção válida passa', () => {
  assert.equal(manutencaoSchema.safeParse(valida).success, true);
});

test('próximo óleo antes da última é recusado', () => {
  const r = manutencaoSchema.safeParse({ ...valida, oleoProxima: '2025-01-01' });
  assert.equal(r.success, false);
});

test('placa extra é recusada', () => {
  const r = manutencaoSchema.safeParse({ ...valida, placa: 'ABC1D23' });
  assert.equal(r.success, false);
});

test('data que não existe no calendário é recusada', () => {
  for (const errada of ['2026-02-31', '2026-02-29', '2026-13-01', '2026-04-31', '2026-00-10']) {
    const r = manutencaoSchema.safeParse({ ...valida, oleoUltima: errada });
    assert.equal(r.success, false, errada);
  }
});

test('29 de fevereiro em ano bissexto passa', () => {
  const r = manutencaoSchema.safeParse({ ...valida, oleoUltima: '2024-02-29', oleoProxima: '2024-08-29' });
  assert.equal(r.success, true);
});

test('ano fora de 1980 a 2100 é recusado', () => {
  assert.equal(manutencaoSchema.safeParse({ ...valida, ipvaProxima: '1979-12-31' }).success, false);
  assert.equal(manutencaoSchema.safeParse({ ...valida, ipvaProxima: '2101-01-01' }).success, false);
});

test('data vazia continua virando nulo', () => {
  const r = manutencaoSchema.safeParse({ ...valida, ipvaProxima: '' });
  assert.equal(r.success, true);
  if (r.success) assert.equal(r.data.ipvaProxima, null);
});

