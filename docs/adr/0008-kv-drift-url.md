# ADR 0008, KV no Drift e URL de ambiente

- Status: aceito
- Data: 2026-08-26

## Contexto

O `context2.md` define a Fase 7: ficha, agenda, extra, foto, preços e último ponto ainda estavam no SharedPreferences; a URL padrão da API estava no cliente. Token, tema e URL de override devem permanecer nas prefs.

## Decisão

- Schema Drift v2: tabela `caderneta_kv` (`chave` PK, `texto`, `bytes`). Foto em blob; o restante em texto JSON (mesmas chaves `*_v1` do backup).
- `ArmazemKv` lê o SQLite e, se vazio, copia a prefs legado e a apaga.
- `MigracaoPrefsDrift` cobre históricos, pins e as chaves KV na primeira abertura.
- SharedPreferences fica com token, refresh, e-mail, tema e `api_base_v1` (campo Servidor).
- URL padrão: `Ambiente.apiPadrao` via `--dart-define=API_BASE`. Sem define: `http://localhost:3001`. O campo Servidor continua sendo o override neste aparelho.

## Consequências

- Cadernetas antigas entram no KV sem o usuário exportar.
- Backup v2 continua com as mesmas chaves JSON; a restauração grava no Drift.
- APK de produção sem `API_BASE` cai no localhost até o piloto preencher o Servidor (LAN).
- UI de conflito e `test/integration/` ficam na Fase 8.
