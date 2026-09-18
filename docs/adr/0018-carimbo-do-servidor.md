# ADR 0018, Carimbo do servidor no sync

- Status: aceito
- Data: 2026-09-17

## Contexto

A política v1 marcava `conflict` sempre que local e remoto divergiam. Num aparelho só, editar a ficha sem rede deixava o local `pending`; na abertura seguinte o servidor (que não mudou) era diferente do local e o app perguntava "fica este ou o do servidor?". A pergunta era falsa e aparecia a cada salvamento offline, e o plano gratuito do Render hiberna a API, o que torna o salvamento offline comum.

O app não tinha como saber se o servidor mudou porque `remote_updated_at` guardava a hora local do sync, e a API não devolvia o `atualizado_em` que já existia nas tabelas.

## Decisão

- `GET` e `PUT` de `/ficha` e `/manutencao` devolvem `atualizadoEm` (ISO UTC, vindo de `UNIX_TIMESTAMP(atualizado_em)`). Esquemas `FichaLida` e `ManutencaoLida` no OpenAPI. O campo é só de leitura; o `PUT` continua `.strict()` e recusa se vier no corpo.
- O app guarda esse carimbo em `remote_updated_at` a cada GET ou PUT bem-sucedido (`LidoDoServidor`, `marcarSincronizado(carimbo:)`).
- Regra ao divergir: com fila local e carimbo do servidor igual ao guardado, reenvia o local sem perguntar. Fora disso, `conflict` como antes. Sem carimbo de um dos lados, também pergunta (comportamento antigo, seguro).
- Opção escolhida: só tirar a pergunta falsa. Quando o servidor mudou de verdade, o piloto continua decidindo. Adotar o servidor em silêncio ("última alteração vence" completo) foi descartado por sobrescrever dado digitado à mão sem aviso.

## Consequências

- `TIMESTAMP` do MySQL tem precisão de segundo. Duas gravações no mesmo segundo têm o mesmo carimbo; irrelevante para uma caderneta preenchida à mão.
- APK antigo ignora `atualizadoEm` e segue com o comportamento anterior. Não há migration.
- Usar o servidor a partir do snapshot de conflito grava sem carimbo; o `carregar()` seguinte, com local igual ao remoto, grava o carimbo certo.
