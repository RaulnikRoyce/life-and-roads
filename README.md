# life.and.roads

Caderneta de **uma moto**: ficha, manutenção, viagem e último ponto no mapa.

App **Flutter** (Android) + API **Node/Express/MySQL**. Local-first: a caderneta funciona neste aparelho sem conta. Login é opcional, para a ficha não sumir na troca de celular.

O mapa é **uma tela**, não o app inteiro. Sem placa, chassi ou RENAVAM — de propósito.

---

## Por que existe

App de moto no Brasil costuma misturar comunidade, FIPE e marketing. Este é o contrário: números que o piloto usa no posto e na oficina, com toque grande e pouca letra.

- **Ficha** — marca, modelo, km do painel, tanque, km/l (gasolina e álcool), PSI, foto, catálogo das motos mais comuns
- **Manutenção** — óleo, pneus, revisão, corrente por **km**, IPVA, seguro, licenciamento, CNH (só a data) + histórico de oficina (km e reais)
- **Viagem** — litros e reais da rota; **álcool vs gasolina** na bomba (R$/km); km na mão ou toque no mapa (km de estrada)
- **Mapa** — GPS, pins de posto/oficina (toque longo)

## Neste aparelho (sem API)

A caderneta inteira funciona offline. O que **não** vai para o servidor:

- PSI dos pneus
- km da última troca de óleo e da corrente
- CNH (só a data de vencimento — sem foto da carteira)
- histórico de serviço na oficina
- pins de posto/oficina
- backup (copiar/colar JSON)

Login continua opcional e só leva ficha + datas de manutenção + último ponto. Schema da API permanece `.strict()`: campo extra é recusado.

Backup: Ficha → **Backup neste aparelho** → Copiar / Colar. Sem conta.

## Catálogo na ficha

Lista opcional com filtro **Cidade | Estrada | Todas**: cubs e scooters (CG, Biz, PCX…) e trail/touring (Bros, Sahara, Royal, Ibex, Ténéré, V-Strom, Triumph, Kawasaki, BMW GS…). Ao escolher:

- preenche marca, cilindrada, tanque, km/l de **gasolina**, PSI e intervalo de óleo
- se for **flex**, preenche km/l de **álcool**; se for só gasolina, o campo fica em branco
- moto de corrente: intervalo ~1.000 km; scooter (PCX, Elite, NMax…) não tem corrente
- mostra uma dica curta (tanque, flex, óleo, pneu)

Os números são de **uso misto**, não de laboratório. O piloto ajusta depois da própria média.

## Stack

| Camada | Tecnologia |
| --- | --- |
| App | Flutter 3.47, Dart 3.13 |
| API | Node, Express 5, Zod, JWT, Helmet, rate limit |
| Banco | MySQL 8 (`life_and_roads`) |
| Mapa | flutter_map + OpenStreetMap (sem chave Google) |
| Persistência local | SharedPreferences |

## Arquitetura

```
┌─────────────────────────────┐
│  Flutter (4 abas)           │
│  SharedPreferences          │  ficha, foto, postos, GPS, manutenção
└──────────────┬──────────────┘
               │ HTTP opcional (JWT)
               ▼
┌─────────────────────────────┐
│  Express :3001              │
│  Zod .strict()              │  recusa placa/chassi/campo extra
└──────────────┬──────────────┘
               ▼
┌─────────────────────────────┐
│  MySQL                      │
│  usuarios, fichas,          │
│  manutencoes, localizacoes  │
└─────────────────────────────┘
```

Uma ficha por piloto. Foto, postos, PSI, km de óleo/corrente, CNH, serviços, pins e backup **não** vão para a API.

**Consumo no posto:** `(km do painel agora − km da ficha) ÷ litros` → km/l daquele combustível.  
**Custo:** `litros × preço ÷ km rodados` → R$/km.

## O que a v1 não faz

iOS · frota · PDF · FIPE · placa · navegação passo a passo · detecção de queda · upload da foto.

## Como rodar

### API

MySQL em `127.0.0.1:3306`. Copie `api/.env.example` para `api/.env` e ajuste senha e `JWT_SECRET`.

```bash
cd api
npm install
# importe api/database/schema.sql no MySQL
npm test
node server.js
```

Sobe em `http://localhost:3001` (`GET /health`).

### App (Chrome)

```bash
cd app
flutter pub get
flutter test
flutter run -d chrome
```

### App (Android)

A caderneta funciona **sem** API. Conta no celular usa o campo **Servidor** (`http://IP-do-PC:3001` na mesma rede), não `localhost`.

```bash
cd app
flutter build apk --release
```

O APK sai em `app/build/app/outputs/flutter-apk/app-release.apk`.

## Testes

- API: `npm test` em `api/` (schema Zod + health)
- App: `flutter test` em `app/` (cálculo de viagem, tanque, R$/km, flex, km da troca, foto local, catálogo, backup, abas)

## Privacidade

Não há campo de placa, chassi ou RENAVAM. O schema da ficha é `.strict()`: campo extra é recusado. Foto e postos ficam só no aparelho.

## Licença

MIT. Ver [LICENSE](LICENSE).
