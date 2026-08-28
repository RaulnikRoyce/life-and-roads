import { z } from 'zod';

const anoMax = new Date().getFullYear() + 1;

const vazioParaNulo = (valor: unknown) => {
  if (valor === '' || valor === undefined) return null;
  return valor;
};

// .strict() recusa placa, chassi, RENAVAM ou qualquer campo extra.
export const fichaSchema = z.object({
  marca: z.string().trim().min(1, 'Marca obrigatória').max(40),
  modelo: z.string().trim().min(1, 'Modelo obrigatório').max(60),
  ano: z.preprocess(
    vazioParaNulo,
    z.number().int().min(1980).max(anoMax).nullable(),
  ),
  cilindrada: z.preprocess(
    vazioParaNulo,
    z.number().int().min(50).max(2000).nullable(),
  ),
  kmLitro: z.number().min(5).max(80),
  kmLitroAlcool: z.preprocess(
    vazioParaNulo,
    z.number().min(5).max(80).nullable(),
  ),
  combustivel: z.enum(['gasolina', 'alcool']).optional().default('gasolina'),
  kmAtual: z.number().min(0).max(999999),
  tanqueLitros: z.preprocess(
    vazioParaNulo,
    z.number().min(2).max(40).nullable(),
  ),
  personalizacoes: z.string().trim().max(200).optional().default(''),
}).strict();

export type FichaDto = z.infer<typeof fichaSchema>;
