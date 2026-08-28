# ADR 0013, Telas em `features/*/presentation`

- Status: aceito
- Data: 2026-08-26

## Contexto

O Context.md pedia `features/*/presentation`. As regras já estavam nas camadas; as telas ainda viviam em `app/lib/ficha/tela_ficha.dart` (e equivalentes). Dívida de caminho, não de arquitetura.

## Decisão

Mover, não reescrever:

- `tela_ficha.dart` → `features/ficha/presentation/`
- `tela_manutencao.dart` → `features/manutencao/presentation/`
- `tela_viagem.dart` → `features/viagem/presentation/`
- `tela_mapa.dart` e `tela_destino.dart` → `features/mapa/presentation/`

Catálogo, `calculo.dart`, `regras.dart` e `Oficina` em `tema.dart` ficam. Sem `go_router`. IndexedStack permanece.

## Consequências

- Imports em `main.dart` e na Viagem (destino). Comportamento idêntico se `flutter test` estiver verde.
- Recorte da v1 intacto.
