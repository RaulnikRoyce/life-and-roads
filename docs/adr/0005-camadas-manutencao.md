# ADR 0005, Camadas na Manutenção

- Status: aceito
- Data: 2026-08-26

## Contexto

O Context.md pede a migração funcionalidade por funcionalidade. A Ficha já tem domínio, repositório e Riverpod. A aba Manutenção ainda lia `manutencao_v1`, chamava a API e misturava km/CNH na mesma classe da UI. Não há Fase 5 nomeada no roadmap; o próximo passo da arquitetura é esta aba.

## Decisão

- Domínio: `AgendaManutencao` (datas que a API replica) + `ManutencaoExtra` (km, CNH, só neste aparelho).
- Dados: `AgendaManutencaoModel` (JSON `manutencao_v1` compatível, sem placa/CNH no payload).
- Repositório: grava local sempre; com conta, PUT last-write-wins; `pending`/`failed` não são sobrescritos pelo GET.
- UI: `TelaManutencao` observa `ManutencaoController`. Lembretes Android continuam na tela após o save.
- Sync das datas: chave `manutencao_sync_v1` no SharedPreferences (as datas já vivem nas prefs; Drift segue só para históricos).

## Consequências

- Backup e cadernetas antigas continuam lendo `manutencao_v1` / `manutencao_km_v1`.
- Restaurar backup com conta marca a agenda como pendente, como a ficha.
- Viagem e Mapa ainda leem JSON solto; migram depois.
- Schema Zod `.strict()` da manutenção não muda.
