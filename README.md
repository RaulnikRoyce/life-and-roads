# life.and.roads

**Beta de testes · v1.3.0 (build 7)**

Caderneta digital de **uma motocicleta**. Ficha, manutenção, viagem e último ponto no mapa.

Flutter (Android) neste aparelho, API Node.js opcional (Express, MySQL, porta **3001**). Sem comunidade, FIPE ou placa. O mapa é uma tela de apoio.

A caderneta funciona offline, sem conta. O login replica ficha, datas de manutenção e o último ponto, para a troca de celular. A API recusa placa, chassi, RENAVAM, foto e qualquer campo fora do schema Zod `.strict()`.

| Aba | O que guarda |
|---|---|
| **Ficha** | marca, modelo, km, tanque, média (álcool só se flex), PSI, foto, catálogo Cidade / Estrada / Esportiva |
| **Manutenção** | óleo, pneus, revisão, corrente, IPVA, seguro, licenciamento, CNH (só a data), oficina |
| **Posto** | custo por km real, abastecimentos e postos, preços do dia |
| **Viagem** | GPS, último ponto, pinos, trajeto com km de estrada e cálculo da viagem |

Backup fica na Ficha, em **Backup neste aparelho**: envia o arquivo pelo compartilhar do Android e restaura pelo seletor de arquivos. Fora da v1 ficam iOS, frota, PDF, navegação passo a passo e envio da foto.

## Beta de testes

Esta é a versão fechada para o período de testes com pilotos. Não é release de loja.

| Item | Detalhe |
|---|---|
| Versão | `1.3.0+7` (`versionName` 1.3.0, `versionCode` 7) |
| APK release | `app/build/app/outputs/flutter-apk/app-release.apk` (65 MB). Exige `android/key.properties` + keystore; sem eles o Gradle recusa o build release |
| Plataforma | Android (APK). Chrome serve para prints e smoke test com Drift web |
| Conta | opcional. Campo **Servidor** com `http://IP-do-PC:3001` no celular |

**Como instalar no celular**

1. Gere o APK com o comando abaixo (ou use o arquivo já gerado após o build).
2. Transfira o APK ao Android e permita instalação de fontes desconhecidas.
3. Abra o app, preencha a ficha e teste as quatro abas sem depender da API.

**Como gerar o APK**

```bash
cd app
flutter pub get
flutter test
flutter build apk --release
```

O build release exige `android/key.properties` + `upload-keystore.jks` (fora do Git). Sem eles o Gradle para com erro, de propósito, para nenhum APK sair com assinatura debug por engano. Para teste interno sem keystore, use `flutter build apk --debug`.

**O que validar nesta build (1.2.1)**

- Abertura com a logo se desenhando e a Ficha como painel (foto, km grande, pastilhas, "Ajustar números")
- Mapa sem a marca "API KEY REQUIRED" (tiles do OpenStreetMap), círculo de alcance, "Abrir no app de mapas", "Onde estou"
- Backup por "Enviar backup" (compartilhar) e "Restaurar de um arquivo"
- Linha do tempo dos vencimentos na Manutenção
- Com conta: abrir o app depois de mais de 15 min sem cair da sessão; linha "No servidor" com hora
- Ficha com catálogo (3 silhuetas por categoria), foto local e backup JSON
- Manutenção com óleo, pneus, documentos e lembretes
- Posto com custo por km real, preços do dia e registro de abastecimento
- Viagem com rastreio, pinos, destino com km de estrada (internet) e cálculo da viagem
- Conta opcional e conflito local versus servidor
- Textos em português comum (sem gíria de posto)

Feedback de bug pode ir por issue no repositório ou canal que o piloto já usa com o autor.

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
