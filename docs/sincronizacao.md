# Sincronização, life.and.roads

A caderneta funciona **neste aparelho**. A API é um cofre opcional da ficha, das **datas de manutenção** e do último ponto. Abastecimentos, serviços, pins, foto, PSI, km de óleo/corrente e CNH **não** sobem.

## Estados (ficha e agenda de manutenção)

| Estado | Significado |
|---|---|
| `synced` | Local e remoto conferem, ou não há conta |
| `pending` | Alteração local à espera da API |
| `failed` | A última tentativa falhou; o retry continua |
| `conflict` | Local e servidor divergem; o piloto escolhe o que fica |

Metadados da ficha no SQLite (`ficha_sync`). Metadados da agenda no SQLite (`caderneta_kv`, chave `manutencao_sync_v1`). Campos: `local_updated_at`, `remote_updated_at`, `sync_status`, `last_sync_error`, `tentativas`.

## Política v1. Última alteração local vence, com pergunta se divergir

1. Grava local sempre.
2. Com conta, tenta o PUT.
3. Se a rede falhar: `pending` ou `failed`. Nada some do aparelho.
4. No próximo `carregar()`, se local e remoto forem **iguais** e houver fila, o app reenvia o local.
5. Se forem **diferentes**, marca `conflict` e pergunta se fica neste aparelho ou se usa a do servidor. PSI, km de troca e CNH não sobem. Ao usar o servidor, esses extras locais permanecem.
6. Sem ficha/agenda local, o GET preenche.

O abastecimento na aba Viagem atualiza a ficha pelo `FichaRepository`. Se a conta existir e o PUT falhar, a ficha fica `pending`/`failed`.

## O que não sincroniza

Históricos, pins, backup, km de troca, CNH. Restaurar um JSON local marca ficha **e** agenda como pendentes se houver token.

Retry: cada abertura da Ficha ou da Manutenção (e o login). Access JWT ~15 min; o app troca o refresh no 401. Sem fila em segundo plano.
