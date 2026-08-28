# ADR 0007, Camadas no Mapa

- Status: aceito
- Data: 2026-08-26

## Contexto

O `context2.md` define a Fase 6 como a aba Mapa. `tela_mapa.dart` lia prefs, chamava `/localizacao` e montava o `TileLayer` OSM no mesmo arquivo da UI. Pins já estavam no Drift.

## Decisão

- Repositório: último ponto (prefs `ultimo_ponto_v1`) + PUT/GET opcional; pins via Drift.
- Use cases: `AcrescentarPino` / `RemoverPino` (só posto ou oficina, sem I/O).
- OSM isolado em `CamadaOsm` / `CreditoOsm` (Mapa e Destino). Sem chave Google.
- GPS (stream, permissão) permanece na tela: plugin nativo + `MapController`.
- UI: `TelaMapa` observa `MapaController`. Throttle de 15 s no envio remoto fica no repositório.

## Consequências

- Backup e testes de `pontoDeJson` / OSRM não mudam.
- Último ponto ainda nas prefs (Fase 7: Drift).
- Schema Zod de localização não muda.
