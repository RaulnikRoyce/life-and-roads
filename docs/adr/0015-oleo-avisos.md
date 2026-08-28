# ADR 0015, Óleo claro, lembrete no aparelho e sininho

- Status: aceito
- Data: 2026-08-26

## Contexto

Na APK 1.2 o óleo tinha jargão de oficina. O lembrete Android descartava data já passada e engolia permissão recusada. Quem não apertava Salvar de novo nunca levava o aviso para o celular.

## Decisão

- Rótulos em linguagem de posto (`Quando você trocou`, `Km do painel na troca`).
- Data passada agenda **amanhã 9h** (Brasília). Se falta mais de 7 dias, agenda também a semana antes.
- Permissão recusada: snackbar PT-BR, sem `catch` mudo.
- Reagendar ao **abrir o app** e ao Salvar.
- Sininho na AppBar com não lidas no Drift KV. Sem API, sem feed.
- Aviso por km no sininho; notificação de sistema só se já estiver atrasado no save/abertura.

## Consequências

- Recorte intacto. Fase 15 (catálogo esportiva) fica para o próximo pedido.
