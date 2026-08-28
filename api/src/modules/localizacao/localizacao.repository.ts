import type { ResultSetHeader, RowDataPacket } from 'mysql2';
import { getPool } from '../../shared/database/pool';
import type { LocalizacaoDto } from './localizacao.schema';

type Linha = RowDataPacket & { latitude: string | number; longitude: string | number };

const paraJson = (linha: Linha | undefined): LocalizacaoDto | null => {
  if (!linha) return null;
  return {
    latitude: Number(linha.latitude),
    longitude: Number(linha.longitude),
  };
};

export async function buscarPorUsuario(usuarioId: number): Promise<LocalizacaoDto | null> {
  const [rows] = await getPool().execute<Linha[]>(
    'SELECT latitude, longitude FROM localizacoes WHERE usuario_id = ?',
    [usuarioId],
  );
  return paraJson(rows[0]);
}

export async function salvar(
  usuarioId: number,
  dados: LocalizacaoDto,
): Promise<LocalizacaoDto> {
  await getPool().execute<ResultSetHeader>(
    `INSERT INTO localizacoes (usuario_id, latitude, longitude)
     VALUES (?, ?, ?)
     ON DUPLICATE KEY UPDATE
        latitude = VALUES(latitude),
        longitude = VALUES(longitude)`,
    [usuarioId, dados.latitude, dados.longitude],
  );
  return dados;
}
