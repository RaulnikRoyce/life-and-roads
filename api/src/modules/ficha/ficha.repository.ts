import type { ResultSetHeader, RowDataPacket } from 'mysql2';
import { getPool } from '../../shared/database/pool';
import type { FichaDto } from './ficha.schema';

type FichaRow = RowDataPacket & {
  marca: string;
  modelo: string;
  ano: number | null;
  cilindrada: number | null;
  km_litro: string | number;
  km_litro_alcool: string | number | null;
  combustivel: string;
  km_atual: string | number;
  tanque_litros: string | number | null;
  personalizacoes: string | null;
  atualizado_em_unix: number | string | null;
};

/** Ficha como sai no GET/PUT: o contrato mais o carimbo do servidor. */
export type FichaLida = FichaDto & { atualizadoEm: string | null };

/** UNIX_TIMESTAMP() não depende do fuso da sessão; ISO em UTC para o app. */
export const carimboIso = (unix: number | string | null | undefined): string | null => {
  const n = Number(unix);
  if (!Number.isFinite(n) || n <= 0) return null;
  return new Date(n * 1000).toISOString();
};

const paraJson = (linha: FichaRow | undefined): FichaLida | null => {
  if (!linha) return null;
  return {
    atualizadoEm: carimboIso(linha.atualizado_em_unix),
    marca: linha.marca,
    modelo: linha.modelo,
    ano: linha.ano,
    cilindrada: linha.cilindrada,
    kmLitro: Number(linha.km_litro),
    kmLitroAlcool: linha.km_litro_alcool == null ? null : Number(linha.km_litro_alcool),
    combustivel: linha.combustivel === 'alcool' ? 'alcool' : 'gasolina',
    kmAtual: Number(linha.km_atual),
    tanqueLitros: linha.tanque_litros == null ? null : Number(linha.tanque_litros),
    personalizacoes: linha.personalizacoes || '',
  };
};

export async function buscarPorUsuario(usuarioId: number): Promise<FichaLida | null> {
  const [rows] = await getPool().execute<FichaRow[]>(
    `SELECT marca, modelo, ano, cilindrada, km_litro, km_litro_alcool, combustivel,
            km_atual, tanque_litros, personalizacoes,
            UNIX_TIMESTAMP(atualizado_em) AS atualizado_em_unix
       FROM fichas WHERE usuario_id = ?`,
    [usuarioId],
  );
  return paraJson(rows[0]);
}

export async function salvar(usuarioId: number, dados: FichaDto): Promise<FichaLida> {
  const params = [
    usuarioId,
    dados.marca,
    dados.modelo,
    dados.ano,
    dados.cilindrada,
    dados.kmLitro,
    dados.kmLitroAlcool ?? null,
    dados.combustivel === 'alcool' ? 'alcool' : 'gasolina',
    dados.kmAtual,
    dados.tanqueLitros ?? null,
    dados.personalizacoes || '',
  ];

  await getPool().execute<ResultSetHeader>(
    `INSERT INTO fichas
        (usuario_id, marca, modelo, ano, cilindrada, km_litro, km_litro_alcool,
         combustivel, km_atual, tanque_litros, personalizacoes)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) AS novo
     ON DUPLICATE KEY UPDATE
        marca = novo.marca,
        modelo = novo.modelo,
        ano = novo.ano,
        cilindrada = novo.cilindrada,
        km_litro = novo.km_litro,
        km_litro_alcool = novo.km_litro_alcool,
        combustivel = novo.combustivel,
        km_atual = novo.km_atual,
        tanque_litros = novo.tanque_litros,
        personalizacoes = novo.personalizacoes`,
    params,
  );
  const [rows] = await getPool().execute<FichaRow[]>(
    'SELECT UNIX_TIMESTAMP(atualizado_em) AS atualizado_em_unix FROM fichas WHERE usuario_id = ?',
    [usuarioId],
  );
  return { ...dados, atualizadoEm: carimboIso(rows[0]?.atualizado_em_unix) };
}
