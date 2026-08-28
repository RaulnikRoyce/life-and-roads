import { z } from 'zod';

const vazioParaNulo = (valor: unknown) => {
  if (valor === '' || valor === undefined) return null;
  return valor;
};

const dataIso = z.preprocess(
  vazioParaNulo,
  z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Data no formato AAAA-MM-DD').nullable(),
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
