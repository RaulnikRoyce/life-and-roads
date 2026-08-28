import { z } from 'zod';

const senhaForte = z.string()
  .min(8, 'Senha deve ter no mínimo 8 caracteres')
  .max(72, 'Senha longa demais');

export const loginSchema = z.object({
  email: z.string().trim().toLowerCase().email('E-mail inválido').max(255),
  senha: senhaForte,
});

export const registrarSchema = z.object({
  email: z.string().trim().toLowerCase().email('E-mail inválido').max(255),
  senha: senhaForte,
});

export const refreshSchema = z.object({
  refreshToken: z.string().trim().min(16, 'Refresh token inválido').max(2000),
});

export const sairSchema = z.object({
  refreshToken: z.string().trim().min(16).max(2000).optional(),
});

export const senhaSchema = z
  .object({
    senhaAtual: senhaForte,
    senhaNova: senhaForte,
  })
  .strict()
  .refine((d) => d.senhaAtual !== d.senhaNova, {
    message: 'A senha nova tem que ser diferente da atual',
    path: ['senhaNova'],
  });
