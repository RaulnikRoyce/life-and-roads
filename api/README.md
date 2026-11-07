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


## Escrita com versão

Os PUTs de `/ficha` e `/manutencao` aceitam `X-Base-Atualizado-Em` com a versão ISO UTC completa retornada no GET/PUT, ou a string `null` para criar somente se ainda não existir registro. A conferência e a escrita são atômicas. Base antiga retorna 409 sem sobrescrever, com a versão atual em `detalhes.atualizadoEm`.

O header é opcional para manter os apps anteriores funcionando. Sua ausência preserva escrita sem conferência, portanto a proteção contra sobrescrita exige cliente atualizado. Publicar a API antes de distribuir o novo app. O formato do corpo permanece estrito. As migrations 006 a 008 acrescentam as versões de ficha/agenda e alinham os campos de consumo ao tipo numérico do app; valores monetários não mudam. A ADR 0050 registra as decisões e os testes.
