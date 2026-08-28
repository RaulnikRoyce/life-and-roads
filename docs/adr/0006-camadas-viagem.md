# ADR 0006, Camadas na Viagem

- Status: aceito
- Data: 2026-08-26

## Contexto

O `context2.md` define a Fase 5 como a aba Viagem. `tela_viagem.dart` lia a ficha em JSON, gravava prefs e fazia PUT da ficha no abastecimento. As fórmulas em `calculo.dart` já estavam testadas.

## Decisão

- Use cases de domínio: `CalcularCustoViagem` e `MontarAbastecimento` (regras; sem I/O).
- Repositório de viagem: preços (`preco_litro_v1` / `preco_alcool_v1`) e histórico Drift.
- Atualização da ficha no posto passa por `FichaRepository.salvar` (last-write-wins, pending se a API cair). Sem `Map` nem GET remoto a cada troca de aba, só `prefs.reload` da ficha local.
- UI: `TelaViagem` observa `ViagemController`. OSM/destino continuam na tela.

## Consequências

- Fórmulas e chaves de backup não mudam.
- Preços ainda nas prefs (Fase 7 do context2: Drift).
- Mapa passou a ter camadas na Fase 6 (`ADR 0007`).
- Schema Zod da ficha não muda.
