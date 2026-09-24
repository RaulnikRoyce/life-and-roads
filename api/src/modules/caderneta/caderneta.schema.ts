import { z } from 'zod';

/**
 * O que a caderneta na nuvem guarda: só o que hoje não sincroniza de outro
 * jeito, e nunca a foto (ADR 0038). A ficha sem PSI, as datas de manutenção e
 * o último ponto têm caminho próprio e ficam fora.
 *
 * O nível de cima é `.strict()`: as chaves são estas e mais nenhuma, então a
 * rota não vira depósito de qualquer coisa. Cada item das listas é um objeto
 * sem forma fixa, para o app poder ganhar campo novo sem quebrar a API; o
 * tamanho do corpo inteiro já é limitado na entrada da rota.
 */

const LIMITE_ITENS = 5000;
const itemLivre = z.record(z.string(), z.unknown());
const textoGuardado = z.string().max(20_000).nullable();
const psi = z.number().int().min(0).max(200).nullable();

export const conteudoSchema = z.object({
  v: z.literal(1),
  abastecimentos: z.array(itemLivre).max(LIMITE_ITENS),
  servicos: z.array(itemLivre).max(LIMITE_ITENS),
  pins: z.array(itemLivre).max(LIMITE_ITENS),
  extra: textoGuardado,
  precoGasolina: textoGuardado,
  precoAlcool: textoGuardado,
  psi: z.object({ dianteiro: psi, traseiro: psi }).strict(),
}).strict();

export const salvarCadernetaSchema = z.object({
  conteudo: conteudoSchema,
  /**
   * O carimbo da nuvem que este aparelho conhece, ou null se nunca viu
   * nenhum. Se o servidor tiver outro, responde 409 e não grava.
   */
  baseAtualizadoEm: z.iso.datetime({ offset: false }).nullable(),
}).strict();

export type ConteudoCaderneta = z.infer<typeof conteudoSchema>;
export type SalvarCadernetaDto = z.infer<typeof salvarCadernetaSchema>;
