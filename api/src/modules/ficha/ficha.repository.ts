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
};

const paraJson = (linha: FichaRow | undefined): FichaDto | null => {
  if (!linha) return null;
  return {
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

export async function buscarPorUsuario(usuarioId: number): Promise<FichaDto | null> {
  const [rows] = await getPool().execute<FichaRow[]>(
    `SELECT marca, modelo, ano, cilindrada, km_litro, km_litro_alcool, combustivel,
            km_atual, tanque_litros, personalizacoes
       FROM fichas WHERE usuario_id = ?`,
    [usuarioId],
  );
  return paraJson(rows[0]);
}

export async function salvar(usuarioId: number, dados: FichaDto): Promise<FichaDto> {
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
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE
        marca = VALUES(marca),
        modelo = VALUES(modelo),
        ano = VALUES(ano),
        cilindrada = VALUES(cilindrada),
        km_litro = VALUES(km_litro),
        km_litro_alcool = VALUES(km_litro_alcool),
        combustivel = VALUES(combustivel),
        km_atual = VALUES(km_atual),
        tanque_litros = VALUES(tanque_litros),
        personalizacoes = VALUES(personalizacoes)`,
    params,
  );
  return dados;
}
