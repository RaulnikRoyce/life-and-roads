const test = require('node:test');
const assert = require('node:assert/strict');
const { localizacaoSchema } = require('../src/schemas/localizacao.schema');

test('ponto válido passa', () => {
    const r = localizacaoSchema.safeParse({ latitude: -23.55, longitude: -46.63 });
    assert.equal(r.success, true);
});

test('latitude 91 é recusada', () => {
    const r = localizacaoSchema.safeParse({ latitude: 91, longitude: 0 });
    assert.equal(r.success, false);
});

test('rastro extra é recusado', () => {
    const r = localizacaoSchema.safeParse({
        latitude: -23.55,
        longitude: -46.63,
        pontos: [{ latitude: 0, longitude: 0 }]
    });
    assert.equal(r.success, false);
});
