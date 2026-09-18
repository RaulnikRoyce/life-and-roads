import { z } from 'zod';

const vazioParaNulo = (valor: unknown) => {
  if (valor === '' || valor === undefined) return null;
  return valor;
};

const ANO_MIN = 1980;
const ANO_MAX = 2100;

/** Regex só garante o formato; aqui a data precisa existir no calendário. */
const dataReal = (texto: string): boolean => {
  const [ano, mes, dia] = texto.split('-').map(Number);
  if (ano < ANO_MIN || ano > ANO_MAX) return false;
  const d = new Date(Date.UTC(ano, mes - 1, dia));
  return d.getUTCFullYear() === ano
    && d.getUTCMonth() === mes - 1
    && d.getUTCDate() === dia;
};

const dataIso = z.preprocess(
  vazioParaNulo,
  z.string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'Data no formato AAAA-MM-DD')
    .refine(dataReal, `Data inexistente ou fora de ${ANO_MIN} a ${ANO_MAX}`)
    .nullable(),
);

const ordemOk = (ultima: string | null, proxima: string | null) => {
  if (!ultima || !proxima) return true;
  return proxima >= ultima;
};

export const manutencaoSchema = z.object({
  oleoUltima: dataIso,
  oleoProxima: dataIso,
  revisaoUltima: dataIso,
  pneusUltima: dataIso,
  pneusProxima: dataIso,
  ipvaProxima: dataIso,
  seguroProxima: dataIso,
  licenciamentoProxima: dataIso,
}).strict().refine(
  (d) => ordemOk(d.oleoUltima, d.oleoProxima),
  { message: 'Próximo óleo não pode ser antes da última troca.', path: ['oleoProxima'] },
).refine(
  (d) => ordemOk(d.pneusUltima, d.pneusProxima),
  { message: 'Próximos pneus não podem ser antes da última troca.', path: ['pneusProxima'] },
);

export type ManutencaoDto = z.infer<typeof manutencaoSchema>;
