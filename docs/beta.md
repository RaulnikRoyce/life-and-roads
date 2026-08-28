# Beta fechado, Play Console

Pacote `com.raulnik.life_and_roads`. Uma moto, quatro abas, API opcional.

Versão do app **1.2.0+4**. O CI **não publica** na loja. Gera o APK assinado num tag `v*` (ex. `v1.2.0`). O upload para o teste fechado é **manual**.

## Secrets do GitHub (só no CI)

- `ANDROID_KEYSTORE_BASE64`, JKS em Base64
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `API_BASE`, URL HTTPS da API de produção (`https://…`, sem barra no fim). Sem este secret o APK cai em `http://localhost:3001` e a conta na loja não funciona. A caderneta neste aparelho segue.

Não commitar `key.properties` nem `.jks`.

## Ficha da Play (teste fechado)

| Campo | Valor |
|---|---|
| Nome | life.and.roads |
| Pacote | com.raulnik.life_and_roads |
| Categoria | Mapas e navegação (ou Estilo de vida) |
| Público | 18+ recomendado (piloto) |
| Privacidade | [docs/privacidade.md](privacidade.md) |
| Termos | [docs/termos.md](termos.md) |
| Exclusão de conta | no app, Ficha, Conta, Excluir conta no servidor |
| Troca de senha | no app, Ficha, Conta, Trocar senha |
| HTTPS | produção da API **tem** que ser HTTPS. O campo Servidor (HTTP na LAN) só aparece no build de desenvolvimento. |

## Data safety (Play)

- Conta (e-mail, senha bcrypt, ficha sem PSI, datas, último ponto), **só com login**.
- Foto, PSI, pins, abastecimentos, backup, **só neste aparelho**.
- GPS, localização aproximada/precisa para o mapa. Sobe o último ponto se houver conta.
- Sem anúncio, sem venda de dados, sem placa.

## Checklist antes do teste

1. `docker compose up --build` e `GET /ready` = ok.
2. API de produção no ar com HTTPS. Secret `API_BASE` preenchido.
3. Tag `v1.2.0`, artifact `app-release` no GitHub Actions.
4. Track **Closed testing**, lista de e-mails testers.
5. Data safety conferida (acima).
6. Sem placa, FIPE, frota.

## Build local (dev)

```bash
cd app
flutter test
flutter build apk --debug
```

Release assinado de loja, tag `v1.2.0` + secrets (incluindo `API_BASE`). Não usar o keystore de upload no repositório.

Fora do código, VPS e domínio são seus. Sem URL real o APK de produção fica sem cofre.
