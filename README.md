# life.and.roads

Caderneta digital de **uma motocicleta**. Ficha, manutenção, viagem e último ponto no mapa.

Flutter (Android) neste aparelho, API Node.js opcional (Express, MySQL, porta **3001**). Sem comunidade, FIPE ou placa. O mapa é uma tela de apoio.

A caderneta funciona offline, sem conta. O login replica ficha, datas de manutenção e o último ponto, para a troca de celular. A API recusa placa, chassi, RENAVAM, foto e qualquer campo fora do schema Zod `.strict()`.

| Aba | O que guarda |
|---|---|
| **Ficha** | marca, modelo, km, tanque, média (álcool só se flex), PSI, foto, catálogo Cidade / Estrada / Esportiva |
| **Manutenção** | óleo, pneus, revisão, corrente, IPVA, seguro, licenciamento, CNH (só a data), oficina |
| **Viagem** | litros e reais da rota, álcool versus gasolina (R$/km), km digitado ou marcado no mapa |
| **Mapa** | GPS, último ponto, pins de posto e oficina (toque longo) |

Backup fica na Ficha, em **Backup neste aparelho**. Fora da v1 ficam iOS, frota, PDF, navegação passo a passo e envio da foto.

## Stack

| Camada | Tecnologia |
|---|---|
| Cliente | Flutter 3 / Dart 3, Material 3 |
| Mapa | flutter_map + OpenStreetMap |
| Local | Drift/SQLite; SharedPreferences (token, tema, URL) |
| API | Node.js 20, TypeScript, Express 5, JWT (access + refresh), Zod, Helmet |
| Banco | MySQL 8, `mysql2/promise` |
| Testes | `flutter test` em `app/`; `npm test` em `api/` |

```
piloto → Flutter (4 abas) → SQLite (Drift)
                 │
                 └── conta opcional → Express :3001 → MySQL
```

Camadas da API, rotas, validação, serviço, repositório. Fórmulas, sync e o desenho completo estão em [docs/arquitetura.md](docs/arquitetura.md). Contrato em [docs/openapi.yaml](docs/openapi.yaml). Requisitos em [docs/especificacao.md](docs/especificacao.md).

## Subir local

Flutter SDK, Node.js 20+ e MySQL em `127.0.0.1:3306`.

```bash
# API
cp api/.env.example api/.env
# importe api/database/schema.sql e preencha o .env
cd api && npm install && npm test && npm start
# http://localhost:3001  GET /health  GET /ready
# ou: docker compose up --build

# App (a caderneta sobe sem a API)
cd app && flutter pub get && flutter test && flutter run -d chrome
```

No celular, a conta usa o campo **Servidor** com `http://IP-do-PC:3001` na mesma rede. `localhost` só vale no Chrome. APK de loja usa `--dart-define=ENV=production --dart-define=API_BASE=https://...`.

## Documentos

- [Especificação](docs/especificacao.md)
- [Arquitetura](docs/arquitetura.md)
- [Sincronização](docs/sincronizacao.md)
- [OpenAPI](docs/openapi.yaml)
- [Privacidade](docs/privacidade.md)
- Decisões de implementação em [`docs/adr/`](docs/adr/)

## Autoria

Ideia, recorte e primeiro código, **RaulnikRoyce**. Evolução do código com auxílio do [Cursor](https://cursor.com).

## Licença

Proprietária. Todos os direitos reservados. Ver [LICENSE](LICENSE).
