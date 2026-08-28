# Arquitetura, life.and.roads

## 1. Visão geral

Dois processos independentes. O aplicativo Flutter é a caderneta; a API Node.js é o cofre opcional.

```mermaid
flowchart LR
  subgraph aparelho ["Aplicativo Flutter"]
    Ficha
    Manutencao["Manutenção"]
    Viagem
    Mapa
    Prefs["SharedPreferences (token, tema, URL)"]
    Sqlite[(SQLite Drift)]
  end
  subgraph servidor ["API Express :3001"]
    Auth["/auth"]
    RF["/ficha"]
    RM["/manutencao"]
    RL["/localizacao"]
    MySQL[(MySQL)]
  end
  Ficha --> Sqlite
  Manutencao --> Sqlite
  Viagem --> Sqlite
  Mapa --> Sqlite
  Ficha --> Prefs
  Ficha -.->|"JWT opcional"| RF
  Manutencao -.-> RM
  Mapa -.-> RL
  Auth --> MySQL
  RF --> MySQL
  RM --> MySQL
  RL --> MySQL
```

A linha pontilhada só existe com conta. Sem login, nada sai do aparelho.

## 2. Camadas da API

Pasta `api/src/`, de fora para dentro. TypeScript em módulos (`auth`, `ficha`, `manutencao`, `localizacao`) e `shared/`.

| Camada | Pasta | Responsabilidade |
|---|---|---|
| Transporte | `src/modules/*/*.routes.ts` | Verb + caminho |
| Validação | `*.schema.ts` + `shared/http/validador.ts` | Zod; ficha em `.strict()` |
| Autenticação | `shared/http/auth.ts` | Bearer access JWT |
| Caso de uso | `*.service.ts` | Regra de negócio |
| Persistência | `*.repository.ts` | SQL via `mysql2/promise` |
| Infraestrutura | `shared/` | Ambiente, pool, migrations, log, erros |

Controladores não acessam o banco. Repositórios não conhecem HTTP.

## 3. Módulos do aplicativo

```
app/lib/
  main.dart              quatro abas (IndexedStack)
  api.dart               cliente HTTP (JWT/refresh)
  core/api/openapi/      DTOs e cliente tipado do OpenAPI
  backup.dart            exportar / restaurar JSON
  tema.dart              paleta e ThemeData
  features/ficha/        domínio, dados, Riverpod da ficha/conta
  features/manutencao/   domínio, dados, Riverpod das datas
  features/viagem/       domínio, dados, Riverpod, use cases da rota/posto
  features/mapa/         domínio, dados, Riverpod, OSM isolado
  ficha/                 catálogo, foto, tela
  manutencao/            regras de data, km, lembretes, serviços, tela
  viagem/                fórmulas, histórico, tela
  mapa/                  GPS, rota, pins, destino, tela
```

As abas permanecem montadas (`IndexedStack`). Viagem e Manutenção relêem a ficha ao ficarem visíveis, para a média e o km do painel recém-salvos valerem no cálculo.

## 4. O que é local e o que é remoto

| Dado | Local | API |
|---|---|---|
| Ficha (marca, modelo, km, tanque, km/l) | sim | sim, com conta |
| PSI | sim | não |
| Foto | sim | não |
| Óleo, pneus, revisão, IPVA, seguro, licenciamento | sim | sim (datas) |
| Km de óleo/corrente, CNH, serviços | sim | não |
| Preço do litro, abastecimentos, R$/km | sim | não |
| Pins e backup | sim | não |
| Último ponto GPS | sim | sim, com conta |

## 5. Fórmulas

Consumo no posto.

\[
km/l = \frac{km_{painel} - km_{ficha}}{litros}
\]

Custo da viagem.

\[
litros = \frac{km_{rota}}{km/l},\quad reais = litros \times preço_{litro}
\]

Custo por quilômetro.

\[
R\$/km = \frac{litros \times preço_{litro}}{km_{rodados}}
\]

Autonomia.

\[
km_{autonomia} = tanque_{L} \times km/l
\]

Flex na bomba compara `preço / km/l` de gasolina e de álcool. O menor R$/km vence.

Papelada anual (IPVA, seguro, licenciamento) soma um ano até a data ficar no futuro. CNH soma 10 anos (ou 5, se marcado). Óleo, última data + 6 meses. Pneus, + 12 meses.

## 6. Persistência local

Caderneta (ficha, foto, agenda, extra, preços, último ponto, históricos, pins e metadados de sync): SQLite (Drift), arquivo `caderneta.sqlite`. Schema v2: tabela `caderneta_kv` para o que era JSON nas prefs.

Na primeira abertura, as chaves `abastecimentos_v1`, `servicos_v1`, `pins_v1`, `ficha_moto_v1`, `manutencao_v1`, `manutencao_km_v1`, `foto_moto_v1`, `preco_litro_v1`, `preco_alcool_v1`, `ultimo_ponto_v1` e `manutencao_sync_v1` migram para o banco e somem das prefs.

SharedPreferences (prefixo `flutter.` na Web) fica só com sessão e aparência:

- `tema_v1`
- `token_life_and_roads`, `refresh_life_and_roads`, `email_life_and_roads`
- `api_base_v1` (override do campo Servidor)

URL padrão da API: `--dart-define=API_BASE=https://...`. Sem define: `http://localhost:3001`.

Backup JSON: versão 2 (listas estruturadas); a restauração ainda lê a versão 1. Ver [sincronizacao.md](sincronizacao.md).

## 7. Segurança da API

- Helmet, CORS explícito, limite de 20 kb no JSON
- 300 requisições / 15 min por IP (`/health` livre)
- Senha com bcrypt (custo 10)
- JWT access nas rotas de ficha, manutenção e localização
- Refresh revogável (`POST /auth/refresh`); exclusão em `DELETE /auth/conta`
- Schema Zod recusa placa, chassi, RENAVAM e qualquer campo não listado
