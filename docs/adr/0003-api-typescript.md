# ADR 0003, API TypeScript, sessão e contrato

- Status: aceito
- Data: 2026-08-26

## Contexto

A API v1 era JavaScript, JWT único de 8 h, `/health` sem banco e testes só de schema. O Context.md pede TypeScript modular, access curto + refresh revogável, readiness, OpenAPI e MySQL nos testes de integração, sem mudar o recorte nem o Zod `.strict()` da ficha.

## Decisão

- TypeScript (tsx) em `api/src/modules/` (`auth`, `ficha`, `manutencao`, `localizacao`) e `shared/`.
- `mysql2/promise`, transação nas migrations, tabela `sessoes`.
- Access JWT ~15 min (`typ: access`). Refresh ~30 dias, hash SHA-256 no MySQL, rotação; reuso revoga a conta.
- `GET /health` liveness; `GET /ready` ping no banco; `X-Request-Id`; shutdown em SIGTERM/SIGINT.
- Contrato em `docs/openapi.yaml`. Teste de integração com MySQL real; se o banco não estiver no ar, o teste é ignorado.
- O app grava o refresh e renova o access no 401.

## Consequências

- Login continua devolvendo `token` (access) para não quebrar o cliente antigo; passa a devolver também `refreshToken`.
- Zod da ficha, manutenção e localização não ganhou campo. PSI, pins e posto seguem só no aparelho.
- `DELETE /auth/conta` apaga usuário e dados remotos (CASCADE).
