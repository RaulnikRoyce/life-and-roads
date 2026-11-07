import { gravarVersionado } from '../../shared/database/gravar-versionado';
import type { ResultSetHeader, RowDataPacket } from 'mysql2';
import { getPool } from '../../shared/database/pool';
import type { ManutencaoDto } from './manutencao.schema';

export type ManutencaoLida = ManutencaoDto & { atualizadoEm: string | null };

type Linha = RowDataPacket & {
  oleo_ultima: string | null;
  oleo_proxima: string | null;
  revisao_ultima: string | null;
  pneus_ultima: string | null;
  pneus_proxima: string | null;
  ipva_proxima: string | null;
  seguro_proxima: string | null;
  licenciamento_proxima: string | null;
  atualizado_em_ms: number | string | null;
};

const SELECT = `SELECT
  DATE_FORMAT(oleo_ultima, '%Y-%m-%d') AS oleo_ultima,
  DATE_FORMAT(oleo_proxima, '%Y-%m-%d') AS oleo_proxima,
  DATE_FORMAT(revisao_ultima, '%Y-%m-%d') AS revisao_ultima,
  DATE_FORMAT(pneus_ultima, '%Y-%m-%d') AS pneus_ultima,
  DATE_FORMAT(pneus_proxima, '%Y-%m-%d') AS pneus_proxima,
  DATE_FORMAT(ipva_proxima, '%Y-%m-%d') AS ipva_proxima,
  DATE_FORMAT(seguro_proxima, '%Y-%m-%d') AS seguro_proxima,
  DATE_FORMAT(licenciamento_proxima, '%Y-%m-%d') AS licenciamento_proxima,
  COALESCE(atualizado_em_ms, UNIX_TIMESTAMP(atualizado_em) * 1000) AS atualizado_em_ms
 FROM manutencoes WHERE usuario_id = ?`;

const paraJson = (linha: Linha | undefined): ManutencaoLida | null => {
  if (!linha) return null;
  return {
    atualizadoEm: new Date(Number(linha.atualizado_em_ms)).toISOString(),
    oleoUltima: linha.oleo_ultima,
    oleoProxima: linha.oleo_proxima,
    revisaoUltima: linha.revisao_ultima,
    pneusUltima: linha.pneus_ultima,
    pneusProxima: linha.pneus_proxima,
    ipvaProxima: linha.ipva_proxima,
    seguroProxima: linha.seguro_proxima,
    licenciamentoProxima: linha.licenciamento_proxima,
  };
};

export async function buscarPorUsuario(usuarioId: number): Promise<ManutencaoLida | null> {
  const [rows] = await getPool().execute<Linha[]>(SELECT, [usuarioId]);
  return paraJson(rows[0]);
}

export async function salvar(
  usuarioId: number,
  dados: ManutencaoDto,
  base?: number | null,
): Promise<ManutencaoLida> {
  const params = [
    usuarioId,
    dados.oleoUltima,
    dados.oleoProxima,
    dados.revisaoUltima,
    dados.pneusUltima,
    dados.pneusProxima,
    dados.ipvaProxima,
    dados.seguroProxima,
    dados.licenciamentoProxima,
  ];

  const atualizadoEm = await gravarVersionado(
    'manutencoes', usuarioId, base, (conn) => conn.execute<ResultSetHeader>(
    `INSERT INTO manutencoes
        (usuario_id, oleo_ultima, oleo_proxima, revisao_ultima, pneus_ultima, pneus_proxima,
         ipva_proxima, seguro_proxima, licenciamento_proxima)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) AS novo
     ON DUPLICATE KEY UPDATE
        oleo_ultima = novo.oleo_ultima,
        oleo_proxima = novo.oleo_proxima,
        revisao_ultima = novo.revisao_ultima,
        pneus_ultima = novo.pneus_ultima,
        pneus_proxima = novo.pneus_proxima,
        ipva_proxima = novo.ipva_proxima,
        seguro_proxima = novo.seguro_proxima,
        licenciamento_proxima = novo.licenciamento_proxima`,
    params,
  ),
  );
  return { ...dados, atualizadoEm };
}
