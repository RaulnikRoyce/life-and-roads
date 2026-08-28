# life.and.roads

Caderneta digital de **uma motocicleta**. Ficha, manutenção, viagem e último ponto no mapa.

Aplicativo Flutter (Android) com persistência neste aparelho e API REST opcional (Node.js, Express, MySQL). Textos em português do Brasil.

## Resumo

O **life.and.roads** guarda os números do painel, do tanque e da oficina para o piloto solo, o motoclube, a viagem a dois e o trecho de fim de semana. Sem comunidade e sem tabela FIPE.

A caderneta completa funciona **neste aparelho**, sem conta. O login replica ficha, datas de manutenção e último ponto, para a troca de celular. A API recusa placa, chassi, RENAVAM, foto e qualquer campo fora do contrato (schema Zod `.strict()`).

Documentos:

- [Especificação de requisitos](docs/especificacao.md)
- [Arquitetura e fórmulas](docs/arquitetura.md)
- [Sincronização](docs/sincronizacao.md)
- [Privacidade e exclusão](docs/privacidade.md)
- [Termos de uso](docs/termos.md)
- [Beta fechado (Play)](docs/beta.md)
- [OpenAPI](docs/openapi.yaml)
- [ADR 0001. Camadas na Ficha](docs/adr/0001-camadas-ficha.md)
- [ADR 0002. SQLite/Drift para históricos e pins](docs/adr/0002-drift-historicos.md)
- [ADR 0003. API TypeScript, sessão e contrato](docs/adr/0003-api-typescript.md)
- [ADR 0004. Operação](docs/adr/0004-operacao.md)
- [ADR 0005. Camadas na Manutenção](docs/adr/0005-camadas-manutencao.md)
- [ADR 0006. Camadas na Viagem](docs/adr/0006-camadas-viagem.md)
- [ADR 0007. Camadas no Mapa](docs/adr/0007-camadas-mapa.md)
- [ADR 0008. KV no Drift e URL de ambiente](docs/adr/0008-kv-drift-url.md)
- [ADR 0009. Confiabilidade](docs/adr/0009-confiabilidade.md)
- [ADR 0010. Troca de senha](docs/adr/0010-troca-de-senha.md)
- [ADR 0011. Release 1.2](docs/adr/0011-release-1-2.md)
- [ADR 0012. Caderneta visível](docs/adr/0012-caderneta-visivel.md)
- [ADR 0013. Telas em presentation](docs/adr/0013-higiene-telas.md)
- [ADR 0014. Viagem em linguagem de posto](docs/adr/0014-viagem-posto.md)
- [ADR 0015. Óleo, lembrete e sininho](docs/adr/0015-oleo-avisos.md)
- [ADR 0016. Catálogo Esportiva e silhueta](docs/adr/0016-catalogo-esportiva.md)

## Objetivos

Geral. Uma caderneta para um único veículo, usável sem rede, com sincronização opcional.

Específicos. (1) registrar ficha e consumo; (2) estimar litros, reais e autonomia da rota; (3) controlar óleo, papelada e CNH; (4) guardar o último ponto no mapa.

## Recorte

Aplicativos de moto no Brasil misturam feed, marketing e consulta veicular. Aqui o centro é km do painel, média, tanque, posto e oficina. Uma moto. Sem placa e sem frota. O mapa é uma tela de apoio.

## Stack

| Camada | Tecnologia |
|---|---|
| Cliente | Flutter 3 / Dart 3, Material 3 |
| Mapa | flutter_map + OpenStreetMap (sem chave Google) |
| Persistência local | Drift/SQLite (caderneta, sync, KV); SharedPreferences (token, tema, URL) |
| API | Node.js 20, TypeScript, Express 5, JWT (access + refresh), Zod, Helmet |
| Banco | MySQL 8 (`utf8mb4`), `mysql2/promise`, migrations em `api/database/migrations/` |
| Testes | `flutter test`; `npm test` na API |

Pastas `app/` (cliente) e `api/` (servidor na porta **3001**). Camadas da API, rotas, validação, serviço, repositório. O cliente não depende da API para a caderneta diária.

## Arquitetura

```
piloto → Flutter (4 abas) → SQLite (Drift)
                 │
                 └── conta opcional → Express :3001 → MySQL
```

Abas **Ficha**, **Manutenção**, **Viagem** e **Mapa**. Detalhamento em [docs/arquitetura.md](docs/arquitetura.md).

### Fórmulas

- Consumo no posto usa `(km do painel − km da ficha) ÷ litros`.
- Viagem usa `km ÷ km/l × preço do litro`.
- Custo usa `litros × preço ÷ km rodados` e vira R$/km.
- Autonomia usa `tanque × km/l`.

## Reprodução

Requisitos. Flutter SDK, Node.js 20+ e MySQL em `127.0.0.1:3306`.

### API

1. Importe `api/database/schema.sql`.
2. Copie `api/.env.example` para `api/.env` e preencha banco e `JWT_SECRET`.
3. Suba o serviço.

```bash
cd api
npm install
npm test
npm start
```

API em `http://localhost:3001`. Saúde em `GET /health`. Pronto em `GET /ready`. Staging local com Docker.

```bash
docker compose up --build
```

Rotas autenticadas (Bearer access JWT) em `GET|PUT /ficha`, `GET|PUT /manutencao` e `GET|PUT /localizacao`. Autenticação em `POST /auth/registrar`, `POST /auth/login` e `POST /auth/refresh`. Exclusão em `DELETE /auth/conta`. Contrato em [docs/openapi.yaml](docs/openapi.yaml). Beta na loja em [docs/beta.md](docs/beta.md).

### Aplicativo

A caderneta funciona sem a API. No desenvolvimento, a conta usa o campo **Servidor** (`http://IP-do-PC:3001` na mesma rede), não `localhost`. Staging e produção escondem o campo. A URL vem de `--dart-define=API_BASE=https://...` (sem define, `http://localhost:3001`).

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
# ou: flutter build apk --release --dart-define=ENV=production --dart-define=API_BASE=https://...
```

O APK sai em `app/build/app/outputs/flutter-apk/app-release.apk`.

## Validação

```bash
cd api && npm test
cd app && flutter test
```

A API cobre schema Zod, `/health`, `/ready` e um fluxo de login/refresh no MySQL (ignorado se o banco não estiver no ar). O aplicativo cobre viagem, tanque, R$/km, flex, km da troca, foto local, catálogo, backup, regras de data, as quatro abas, conflito de sync e os fluxos em `test/integration/`.

## Recorte da v1

| Aba | Conteúdo |
|---|---|
| **Ficha** | marca, modelo, km, tanque, média (álcool só se flex), PSI, foto, catálogo Cidade / Estrada / Esportiva |
| **Manutenção** | óleo, pneus, revisão, corrente por km, IPVA, seguro, licenciamento, CNH (somente a data), histórico de oficina |
| **Viagem** | litros e reais da rota; álcool versus gasolina (R$/km); km digitado ou marcado no mapa |
| **Mapa** | GPS, último ponto, pins de posto/oficina (toque longo) |

Backup fica em Ficha, no bloco **Backup neste aparelho** (Copiar, Salvar arquivo, Colar, Restaurar do arquivo).

Fora da v1, iOS, frota, PDF, FIPE, placa, navegação passo a passo, detecção de queda, envio da foto ao servidor.

## Autoria

Ideia, recorte e primeiro código, **RaulnikRoyce**. Alterações posteriores (catálogo, polimento, fechamento) com auxílio do [Cursor](https://cursor.com), coautor neste repositório.

## Licença

Proprietária. Todos os direitos reservados. Ver [LICENSE](LICENSE).
