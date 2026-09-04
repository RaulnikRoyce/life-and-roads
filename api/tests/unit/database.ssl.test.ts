import { test } from 'node:test';
import assert from 'node:assert/strict';
import { sslBanco } from '../../src/shared/database/pool';

test('banco local não força SSL sem certificado', () => {
  const anterior = process.env.DB_SSL_CA_BASE64;
  delete process.env.DB_SSL_CA_BASE64;
  try {
    assert.equal(sslBanco(), undefined);
  } finally {
    if (anterior !== undefined) process.env.DB_SSL_CA_BASE64 = anterior;
  }
});

test('banco remoto valida a CA informada', () => {
  const anterior = process.env.DB_SSL_CA_BASE64;
  process.env.DB_SSL_CA_BASE64 = Buffer.from(
    '-----BEGIN CERTIFICATE-----\nTESTE\n-----END CERTIFICATE-----',
  ).toString('base64');
  try {
    const ssl = sslBanco();
    assert.equal(typeof ssl, 'object');
    assert.equal((ssl as { rejectUnauthorized?: boolean }).rejectUnauthorized, true);
  } finally {
    if (anterior === undefined) delete process.env.DB_SSL_CA_BASE64;
    else process.env.DB_SSL_CA_BASE64 = anterior;
  }
});

test('CA inválida é recusada', () => {
  const anterior = process.env.DB_SSL_CA_BASE64;
  process.env.DB_SSL_CA_BASE64 = Buffer.from('não é certificado').toString('base64');
  try {
    assert.throws(() => sslBanco(), /certificado PEM válido/);
  } finally {
    if (anterior === undefined) delete process.env.DB_SSL_CA_BASE64;
    else process.env.DB_SSL_CA_BASE64 = anterior;
  }
});
