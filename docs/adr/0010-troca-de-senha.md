# ADR 0010, Troca de senha e revogação de refresh

- Status: aceito
- Data: 2026-08-26

## Contexto

O Context.md pedia invalidar sessão em troca de senha. Existiam `usuarios.ativo` e `sessoes.revogada`, mas não havia `POST /auth/senha`. O único reset remoto era excluir a conta.

## Decisão

- `POST /auth/senha` autenticado: `{ senhaAtual, senhaNova }` (Zod, mín. 8, `.strict()`). Senha nova igual à atual é 400.
- bcrypt da nova; **revoga todos** os refresh daquele `usuario_id`; emite um par novo para este aparelho.
- Access antigo dos outros aparelhos expira sozinho (~15 min). Sem e-mail de recuperação, 2FA ou flag `ativo` na UI.
- App: use case `TrocarSenha` + Ficha → Conta (logado). Aviso PT-BR. Este aparelho permanece logado.

## Consequências

- Outro aparelho precisa entrar de novo depois da troca.
- Recorte da v1 intacto: uma moto, quatro abas, OSM, API opcional.
