# ADR 0021, Sync visível e crash com contexto

- Status: aceito
- Data: 2026-09-18

## Contexto

O piloto só sabia do servidor quando dava errado. Não havia como ver se a caderneta estava em dia nem como forçar uma sincronização. O relato de crash tinha só tipo e mensagem e ia para o log do Render, que some em dias.

## Decisão

- `LinhaSync` na Ficha e na Manutenção, só com conta e fora de conflito. Em dia: "No servidor. Atualizado dd/mm HH:MM" (carimbo do ADR 0018, em hora local). Com fila: "Aguardando o servidor desde dd/mm HH:MM" e o motivo. Última tentativa falhou sem fila: "Sem resposta do servidor. Caderneta neste aparelho." Botão "Sincronizar agora" chama o `carregar()` de sempre.
- Sem "última sincronização às" como campo novo: o carimbo do servidor já diz quando o dado que está lá foi gravado, e isso é o que importa. Evita coluna nova no Drift.
- `/monitor/evento` aceita `versaoApp`, `plataforma` e `pilha` (opcionais, `.strict()`), grava em `eventos_cliente` (migration 003) além do log, com retenção de 90 dias na limpeza diária. Banco fora do ar não derruba o relato.
- `APP_VERSION` chega por `--dart-define` no CI (`tag+run`); build local é "dev". Plataforma vem de `Platform.operatingSystem` + versão, com stub para o Chrome.

## Consequências

- `docs/privacidade.md` atualizado: o crash leva versão, sistema e começo da pilha; nada do piloto.
- Consultar crashes é `SELECT` na tabela por enquanto. Uma rota protegida para ler fica para quando houver necessidade.
