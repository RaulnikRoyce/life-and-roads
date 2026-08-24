const { z } = require('zod');

const senhaForte = z.string()
    .min(8, 'Senha deve ter no mínimo 8 caracteres')
    .max(72, 'Senha longa demais');

exports.loginSchema = z.object({
    email: z.string().trim().toLowerCase().email('E-mail inválido').max(255),
    senha: senhaForte
});

exports.registrarSchema = z.object({
    email: z.string().trim().toLowerCase().email('E-mail inválido').max(255),
    senha: senhaForte
});
