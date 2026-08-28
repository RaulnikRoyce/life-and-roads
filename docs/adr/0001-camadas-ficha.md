# ADR 0001, Camadas na Ficha

- Status: aceito
- Data: 2026-08-26

## Contexto

A aba Ficha validava números, montava `Map<String, dynamic>`, gravava `SharedPreferences` e chamava a API na mesma classe da UI. O Context.md pede modelos tipados, repositório e estado explícito, sem overengineering.

## Decisão

- Domínio: `FichaMoto` com faixas de validação.
- Dados: `FichaMotoModel` (JSON local `ficha_moto_v1` compatível + `toApiJson` sem PSI).
- Repositórios: Ficha (local + remoto opcional) e Auth (token, e-mail, URL).
- UI: `TelaFicha` observa `FichaController` (Riverpod). Loading, erro e offline saem do controller.
- Store local da ficha nesta fase: **SharedPreferences**. Drift fica na Fase 2 (históricos, pins, backup versionado).

## Consequências

- Cadernetas e backups já gravados continuam lendo a mesma chave.
- Viagem e Manutenção ainda leem JSON solto; migram depois.
- PSI continua só no aparelho. A API `.strict()` não muda.
