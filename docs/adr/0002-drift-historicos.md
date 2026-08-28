# ADR 0002, SQLite/Drift para históricos e pins

- Status: aceito
- Data: 2026-08-26

## Contexto

SharedPreferences guardava JSON de abastecimentos, serviços e pins. O Context.md pede Drift para dados estruturados, migrations locais, backup versionado e estados de sincronização. A ficha, o token e o tema continuam sendo preferências.

## Decisão

- SQLite via Drift (`caderneta.sqlite`), schemaVersion 1: tabelas `abastecimentos`, `servicos`, `pins`, `ficha_sync`.
- Migração única das chaves `abastecimentos_v1`, `servicos_v1` e `pins_v1`.
- Backup **v2** exporta listas estruturadas; a restauração aceita v1 (string) e v2.
- Metadados de sync só na **ficha** (única entidade desta fatia que vai à API): `synced`, `pending`, `failed`, `conflict`.
- Política v1: última alteração local vence. `pending`/`failed` reenviam no próximo `carregar()`; o GET remoto não sobrescreve fila local.
- Telas de Viagem, Manutenção e Mapa ainda usam as fachadas estáticas; o armazenamento por baixo é o Drift.

## Consequências

- Cadernetas já gravadas nas chaves v1 entram no SQLite na primeira abertura.
- Pins, posto e oficina continuam só neste aparelho.
- Drift (Fase 3 da API TypeScript) não muda o schema Zod.
