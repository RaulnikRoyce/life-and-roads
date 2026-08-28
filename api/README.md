# API TypeScript (Express)

Servidor REST do **life.and.roads** na porta **3001**. Módulos: `auth`, `ficha`, `manutencao`, `localizacao`. Schema em `database/schema.sql`; migrations em `database/migrations/`. Contrato: [OpenAPI](../docs/openapi.yaml).

```bash
npm install
npm test
npm start
```

| Método | Caminho | Autenticação |
|---|---|---|
| GET | `/health` | não (liveness) |
| GET | `/ready` | não (MySQL) |
| GET | `/openapi.yaml` | não |
| POST | `/auth/registrar`, `/auth/login`, `/auth/refresh` | não (limite 20 / 15 min) |
| POST | `/auth/sair` | refresh no corpo |
| DELETE | `/auth/conta` | access JWT |
| GET, PUT | `/ficha`, `/manutencao`, `/localizacao` | access JWT |

Access ~15 min. Refresh ~30 dias, rotacionado e revogável. O contrato da ficha continua `.strict()`: placa, chassi, RENAVAM ou campo extra é recusado.

Documentação do repositório: [README](../README.md), [especificação](../docs/especificacao.md), [arquitetura](../docs/arquitetura.md), [sincronização](../docs/sincronizacao.md).
