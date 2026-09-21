import { z } from 'zod';

const senhaForte = z.string()
  .min(8, 'Senha deve ter no mínimo 8 caracteres')
  .max(72, 'Senha longa demais');

const emailValido = z.string().trim().toLowerCase().email('E-mail inválido').max(255);

export const loginSchema = z.object({
  email: emailValido,
  senha: senhaForte,
});

export const registrarSchema = z.object({
  email: emailValido,
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

export const recuperarSchema = z
  .object({
    email: emailValido,
  })
  .strict();

export const redefinirSchema = z
  .object({
    email: emailValido,
    codigo: z.string().trim().regex(/^[0-9]{6}$/, 'Código deve ter 6 dígitos'),
    senhaNova: senhaForte,
  })
  .strict();
