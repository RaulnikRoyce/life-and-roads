# life.and.roads

Caderneta de **uma moto**: ficha, manutenção, viagem e último ponto no mapa.

## Sobre este projeto

Este repositório faz parte de um **projeto pessoal**. O objetivo é treinar um produto real da minha atuação como **piloto** — motoclube, viagem a dois, estrada no fim de semana: km do painel, tanque, posto, óleo e o “cabe nesta bomba?”. O tipo de caderneta que uso na moto, não um feed de comunidade.

O life.and.roads nasceu **solo**: as quatro abas, o recorte (sem placa, sem FIPE, mapa como **uma tela**) e o primeiro código foram definidos e escritos por mim. **Perto do final**, usei o [Cursor](https://cursor.com) só como **auxílio estratégico** (catálogo, polimento e fechamento) para concluir o projeto — não como autor da ideia nem do desenho inicial.

## Por quê esta arquitetura

App de moto no Brasil costuma misturar comunidade, tabela e marketing. Este é o contrário: números do posto e da oficina, toque grande, pouca letra.

A caderneta inteira funciona **neste aparelho**, sem conta. Login é opcional (ficha + datas de manutenção + último ponto), para não sumir na troca de celular. A API não recebe placa, chassi, foto, PSI, pins nem backup: o schema é `.strict()` e campo extra é recusado. Uma ficha por piloto.

## Stack

Flutter (Android) · Dart · Node.js · Express · MySQL · JWT · Zod · flutter_map + OpenStreetMap (sem chave Google)

## Subir local

1. MySQL em `127.0.0.1:3306` e importe `api/database/schema.sql`
2. Copie `api/.env.example` para `api/.env` e preencha o banco + `JWT_SECRET`
3. Instale e suba a API:

```bash
cd api
npm install
npm test
node server.js
```

API em `http://localhost:3001`. Saúde: `GET /health`.

4. App (Chrome ou Android). A caderneta **não precisa** da API. No celular, conta usa o campo **Servidor** (`http://IP-do-PC:3001` na mesma rede), não `localhost`.

```bash
cd app
flutter pub get
flutter test
flutter run -d chrome
# ou: flutter build apk --release
```

O APK sai em `app/build/app/outputs/flutter-apk/app-release.apk`.

## Testes

```bash
cd api && npm test
cd app && flutter test
```

API: schema Zod + health. App: viagem, tanque, R$/km, flex, km da troca, foto local, catálogo, backup, abas.

## Abas

| Aba | O que guarda |
|---|---|
| **Ficha** | marca, modelo, km, tanque, km/l (gasolina; álcool só se for flex), PSI, foto, catálogo Cidade/Estrada |
| **Manutenção** | óleo, pneus, revisão, corrente por km, IPVA, seguro, licenciamento, CNH (só a data), histórico de oficina |
| **Viagem** | litros e reais da rota; álcool vs gasolina na bomba (R$/km); km na mão ou toque no mapa |
| **Mapa** | GPS, último ponto, pins de posto/oficina (toque longo) |

**Consumo no posto:** `(km do painel agora − km da ficha) ÷ litros` → km/l. **Custo:** `litros × preço ÷ km rodados` → R$/km.

Backup: Ficha → **Backup neste aparelho** → Copiar / Colar. Sem conta.

v1 não faz: iOS · frota · PDF · FIPE · placa · navegação passo a passo · detecção de queda · upload da foto.

## Licença

Proprietária. Todos os direitos reservados. Ver [LICENSE](LICENSE).
