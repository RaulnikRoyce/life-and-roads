import { getPool } from '../../shared/database/pool';

export type EventoCliente = {
  tipo: string;
  mensagem: string;
  ambiente: string | null;
  versaoApp: string | null;
  plataforma: string | null;
  pilha: string | null;
};

/** Crash do app, sem PII. O log do Render some em dias; a tabela fica. */
export async function gravarEvento(e: EventoCliente): Promise<void> {
  await getPool().execute(
    `INSERT INTO eventos_cliente (tipo, mensagem, ambiente, versao_app, plataforma, pilha)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [e.tipo, e.mensagem, e.ambiente, e.versaoApp, e.plataforma, e.pilha],
  );
}

/** Mantém 90 dias. Chamado junto com a limpeza de sessões. */
export async function apagarEventosAntigos(): Promise<number> {
  const [r] = await getPool().execute<import('mysql2').ResultSetHeader>(
    'DELETE FROM eventos_cliente WHERE criado_em < NOW() - INTERVAL 90 DAY',
  );
  return r.affectedRows;
}
