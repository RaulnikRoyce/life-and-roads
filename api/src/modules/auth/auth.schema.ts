import { z } from 'zod';

const senhaForte = z.string()
  .min(8, 'Senha deve ter no mínimo 8 caracteres')
  .max(72, 'Senha longa demais');

const emailValido = z.string().trim().toLowerCase().email('E-mail inválido').max(255);

export const loginSchema = z.object({
  email: emailValido,
  senha: senhaForte,
});

/**
 * A versão dos Termos de uso e da Privacidade é a data do texto aceito
 * (ADR 0038). O servidor guarda o que o app mostrou, sem conferir se é a
 * mais nova.
 */
const versaoTermos = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Versão dos termos inválida');

export const registrarSchema = z.object({
  email: emailValido,
  senha: senhaForte,
  // Opcional enquanto o APK antigo, que não manda o campo, cadastrar.
  termosVersao: versaoTermos.optional(),
});

export const termosSchema = z.object({
  versao: versaoTermos,
}).strict();

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
