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
