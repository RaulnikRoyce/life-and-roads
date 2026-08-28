# ADR 0004, Operação (Docker, CI, loja)

- Status: aceito
- Data: 2026-08-26

## Contexto

Fases 1–3 deixaram app e API testáveis. O Context.md pede Docker, staging, CI, crash reporting, monitoramento e preparação de beta na loja, sem microsserviços e sem mudar o recorte.

## Decisão

- `docker-compose.yml`: MySQL 8 + API TypeScript (staging local).
- `APP_ENV`: development | staging | production. Logs JSON com `env` e `request_id`. `/health` inclui uptime e contagem de 5xx.
- Crash do app: `POST /monitor/evento` (mensagem curta, sem PII). Ligado só com `--dart-define=ENV=staging|production` ou `CRASH_REPORTING=true`.
- GitHub Actions: `npm test` + `flutter analyze/test` em todo push; APK **assinado só em tag `v*`**, keystore em secrets.
- Termos, privacidade e exclusão de conta no app (exigência da Play). O CI não faz upload na loja.

## Consequências

- Build de loja não vive no repositório. Keystore local do desenvolvedor continua gitignorado.
- HTTP claro no APK da v1 (IP da LAN). Produção da API deve ser HTTPS.
- Sem Sentry/Firebase: um serviço a menos; o monitoramento é a própria API.
