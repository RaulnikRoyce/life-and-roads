# ADR 0011, Release 1.2 (loja sem mudar o produto)

- Status: aceito
- Data: 2026-08-26

## Contexto

A última APK pública era pré-arquitetura; o número ainda era `1.1.0+3`. Em produção, sem `API_BASE`, a URL caía em localhost. O campo Servidor (IP da LAN) não cabe na loja.

## Decisão

- `app/pubspec.yaml`: `1.2.0+4`.
- `Ambiente.exibeCampoServidor`: visível só em development. Staging e produção usam `--dart-define=API_BASE` e ignoram o override das prefs.
- CI: tag `v*` gera APK com `ENV=production`. Secret `API_BASE` (HTTPS). Sem ele o APK de loja fica sem cofre; a caderneta local segue.
- Upload na Play continua **manual** (ADR 0004). Checklist em `docs/beta.md` (Data safety, HTTPS, tag `v1.2.0`).

## Consequências

- Conta na loja exige VPS/HTTPS seus. Sem URL, o app continua offline-first.
- Recorte da v1 intacto: uma moto, quatro abas, OSM, API opcional.
