/**
 * Processo da API (porta 3001 por omissão).
 * Variáveis em `.env`; modelo em `.env.example`.
 */
if (process.env.NODE_ENV !== 'production') {
  require('dotenv').config();
  require('dotenv').config({ path: '.env.local', override: true });
}

import type { Server } from 'http';
import { carregarEnv } from './shared/config/env';
import { fecharPool } from './shared/database/pool';
import { migrar } from './shared/database/migrar';
import { apagarSessoesVencidas } from './modules/auth/auth.repository';
import { logger } from './shared/http/logger';
import app from './app';

let env;
try {
  env = carregarEnv();
} catch (erro) {
  logger.error(erro instanceof Error ? erro.message : 'env');
  process.exit(1);
}

let server: Server;

const limparSessoes = async (): Promise<void> => {
  try {
    const apagadas = await apagarSessoesVencidas();
    if (apagadas > 0) logger.info('sessoes_vencidas_apagadas', { apagadas });
  } catch (erro) {
    logger.error('Falha ao limpar sessões vencidas', {
      detalhe: erro instanceof Error ? erro.message : 'erro',
    });
  }
};

const subir = async (): Promise<void> => {
  try {
    await migrar();
  } catch (erro) {
    logger.error('Falha nas migrations', {
      detalhe: erro instanceof Error ? erro.message : 'erro',
    });
    process.exit(1);
  }

  await limparSessoes();
  const diario = setInterval(() => { void limparSessoes(); }, 24 * 60 * 60 * 1000);
  diario.unref();

  server = app.listen(env.port, '0.0.0.0', () => {
    logger.info(`API life.and.roads em 0.0.0.0:${env.port}`, {
      env: process.env.APP_ENV || process.env.NODE_ENV || 'development',
    });
  });
};

const encerrar = async (sinal: string): Promise<void> => {
  logger.info('shutdown', { sinal });
  if (server) {
    await new Promise<void>((resolve) => server.close(() => resolve()));
  }
  await fecharPool();
  process.exit(0);
};

process.on('SIGTERM', () => {
  void encerrar('SIGTERM');
});
process.on('SIGINT', () => {
  void encerrar('SIGINT');
});

void subir();
