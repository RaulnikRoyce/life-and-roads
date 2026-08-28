# ADR 0009, Conflito de sync, testes de integração e cliente OpenAPI

- Status: aceito
- Data: 2026-08-26

## Contexto

O `context2.md` define a Fase 8 como confiabilidade. O estado `conflict` existia nos metadados, mas o GET remoto sobrescrevia a caderneta local (ou o pending reenviava sem perguntar). Não havia `test/integration/` nem um cliente Dart alinhado ao OpenAPI.

## Decisão

- Se ficha/agenda local e remota divergem nos campos da API, o app **não** aplica o GET nem o PUT. Marca `conflict`, guarda um snapshot e mostra `CartaoConflito`: **Manter esta** (PUT local) ou **Usar a do servidor** (grava a remota, PSI/km/CNH locais sobrevivem).
- Agenda vazia continua baixando o remoto (primeiro aparelho). Sem ficha local, o GET preenche.
- Cliente tipado em `app/lib/core/api/openapi/` (DTOs = `components.schemas` do YAML). Transporte JWT/refresh permanece em `ApiCaderneta`.
- `test/integration/` cobre tema, orientação (`DuplaCampos`), GPS recusado, câmera (texto), offline, conflito entre aparelhos e sessão sem conta.

## Consequências

- A política “última alteração local vence” passa a ser **uma escolha do piloto**, não automática, quando há divergência.
- Schema Zod e colunas MySQL não mudam (sem `updated_at` no JSON).
- Recorte da v1 intacto: uma moto, quatro abas, OSM, API opcional.
