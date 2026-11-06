# life.and.roads

Caderneta digital de **uma motocicleta**, com ficha, manutenção, abastecimentos e viagens. Desenvolvida a partir do uso na estrada e dos testes com pilotos.

**Beta aberto** · [Abrir app web](https://app.raulnikroyce.dev/) · [Baixar APK Android](https://github.com/RaulnikRoyce/life-and-roads/releases/latest/download/life-and-roads-beta-aberto.apk)

## Versão 1.5.3

O código está em `1.5.3+13` no `pubspec.yaml`. Nas publicações pelo CI, o número do build vem da execução do GitHub Actions. O APK e as notas ficam na [Release 1.5.3](https://github.com/RaulnikRoyce/life-and-roads/releases/tag/v1.5.3); a disponibilidade do arquivo e da web depende da conclusão dos jobs de publicação.

A versão 1.5.3 mantém a edição de abastecimentos da 1.5.2 e reúne estas melhorias:

- Calibração das barrinhas por moto, capacidade do tanque e total de segmentos, com faixa estimada após três referências para o mesmo nível.
- Exclusão de abastecimentos com confirmação e recálculo do histórico, das médias e da calibração.
- Identificação do consumo medido, estimado e de períodos com mistura de combustíveis.
- Aviso de nova versão no Android, com acesso ao APK oficial quando estiver disponível na Release.
- Cache de Gradle e NDK e novas tentativas de instalação do NDK no CI.
- Preservação da referência de consumo nos novos registros para restaurá-la após excluir uma medição. Históricos antigos sem essa informação não permitem recuperar o valor original.

Um push comum na `main` executa as verificações e prepara o cache Android. Publicar uma tag `v*` aciona os jobs de APK e web; o app web também pode ser publicado por execução manual do workflow.

## O que o app oferece

| Aba | Recursos |
|---|---|
| **Ficha** | Marca, modelo, km, tanque, consumo, PSI, foto local e catálogo com 116 modelos nas categorias Cidade, Trail, Estrada e Esportiva. |
| **Manutenção** | Óleo, pneus, revisão, corrente, vencimentos de documentos, data da CNH, oficina e histórico de serviços. |
| **Posto** | Abastecimentos completos e parciais, consumo entre tanques cheios, custo por km, preços do dia e correção do histórico. |
| **Viagem** | Mapa OpenStreetMap, GPS, pinos, trajetos, distância por estrada e estimativa de custo da viagem. |

O consumo medido usa a distância e os abastecimentos de um ciclo entre dois tanques cheios. Compras parciais entram no total desse período. A consulta pelas barrinhas estima combustível restante; ela não substitui a medição de consumo.

## Android e web

No Android, a caderneta funciona sem internet e sem conta. Rotas por estrada, sincronização e consulta de atualizações precisam de conexão. Há lembretes de manutenção e backup automático em `Download/life.and.roads/caderneta.json`, conforme as permissões e configurações do aparelho.

A [versão web](https://app.raulnikroyce.dev/) guarda a caderneta no navegador e pode ser adicionada à tela inicial. Atualmente exige internet para abrir, não oferece notificações de manutenção do sistema nem backup automático em pasta fixa. O app nativo para iOS está planejado; ainda não há versão na App Store.

Sem conta, APK e navegador mantêm cadernetas separadas. Com conta e sincronização habilitada, os dados podem acompanhar a troca de aparelho. A foto permanece local.

## Conta, backup e privacidade

A conta é opcional. Ficha, datas de manutenção e último ponto usam suas rotas de sincronização. Os demais dados da caderneta seguem cifrados para a conta, com AES-256-GCM no servidor, após aceite dos termos e com o interruptor de envio ligado. Conflitos entre versões recebem tratamento próprio antes de substituir os dados.

O bloco **Backup neste aparelho**, na Ficha, permite exportar e restaurar a caderneta. As opções de compartilhar, baixar e copiar variam por plataforma. Guarde uma cópia fora do aparelho.

Token e refresh token usam `flutter_secure_storage`. SharedPreferences guarda preferências como e-mail, tema e endereço da API. Os dados da caderneta ficam no Drift/SQLite. Placa, chassi, RENAVAM e upload de foto não fazem parte do produto; os contratos da API usam validação Zod estrita.

## Stack e arquitetura

| Camada | Tecnologias |
|---|---|
| App | Flutter, Dart, Material 3 e Riverpod |
| Armazenamento local | Drift/SQLite e armazenamento seguro para a sessão |
| Mapa | flutter_map e OpenStreetMap |
| API | Node.js 20+, TypeScript, Express 5, JWT, Zod e Helmet |
| Banco da API | MySQL 8 e mysql2/promise |
| Hospedagem | API no Render, banco na Aiven e app web no GitHub Pages |
| Verificação | Flutter Test, análise estática, testes da API e GitHub Actions |

```text
Flutter (Ficha, Manutenção, Posto, Viagem) → SQLite no aparelho
                      │
                      └── conta opcional → API Express :3001 → MySQL
```

O app separa apresentação, regras de domínio e acesso aos dados. Na API, o fluxo é rota, controller, service e repository. As decisões e limitações estão nas [ADRs](docs/adr/).

## Executar localmente

Requer Flutter com Dart compatível com `app/pubspec.yaml` e Node.js 20+. MySQL é necessário para a API e seus testes de integração. A caderneta pode ser usada sem subir a API.

**App**, a partir da raiz do repositório:

```bash
cd app
flutter pub get
flutter run -d chrome
```

Para Android, conecte um aparelho ou emulador e use `flutter run`. No desenvolvimento, o campo **Servidor** aceita `http://IP-do-PC:3001`; no emulador Android, o host normalmente é `http://10.0.2.2:3001`.

**API**, a partir da raiz:

1. Copie `api/.env.example` para `api/.env` e preencha a configuração local.
2. Prepare o MySQL com `api/database/schema.sql`, conforme as instruções da [API](api/README.md).
3. Execute:

```bash
cd api
npm ci
npm start
```

A API responde na porta 3001. `GET /health` verifica o processo e `GET /ready` verifica a disponibilidade do banco. Como alternativa, consulte o `docker-compose.yml` para subir o ambiente com Docker.

## Testes

Execute cada bloco a partir da raiz do repositório:

```bash
cd app
flutter analyze --no-fatal-infos
flutter test
```

```bash
cd api
npm run typecheck
npm test
```

Na conferência local de 06/11/2026, passaram **359 testes do app**, a análise pelo comando `dart analyze` e o build web. O `flutter analyze` apresentou erro interno no servidor de análise do SDK local. Na API, passaram o TypeScript e 64 testes; 29 testes de integração foram pulados por falta de MySQL local. Esses resultados locais não substituem a conclusão do CI, que configura seu próprio MySQL.

## APK e publicação

O APK para instalar está nas [Releases](https://github.com/RaulnikRoyce/life-and-roads/releases). O beta é distribuído diretamente, sem publicação em loja.

Para gerar um release local, configure `app/android/key.properties` e o keystore, ambos fora do Git. O Gradle recusa o release sem assinatura configurada. A partir de `app/`:

```bash
flutter build apk --release --dart-define=ENV=production --dart-define=API_BASE=https://api.raulnikroyce.dev
```

O arquivo é gerado em `app/build/app/outputs/flutter-apk/app-release.apk`, relativo à raiz do repositório. Para depuração sem keystore de release, use `flutter build apk --debug`.

No CI, a versão vem da tag e o build da execução; o APK é assinado com os secrets configurados. O workflow também publica a versão web. Alterações na `main` não geram uma nova release automaticamente.

## Documentação

- [Especificação](docs/especificacao.md)
- [Arquitetura](docs/arquitetura.md)
- [Sincronização](docs/sincronizacao.md)
- [Contrato OpenAPI](docs/openapi.yaml)
- [Privacidade](docs/privacidade.md)
- [Termos de uso](docs/termos.md)
- [Decisões de implementação](docs/adr/)

## Autoria e licença

Ideia, recorte e primeiro código de **RaulnikRoyce**. Evolução com apoio de ferramentas de IA, incluindo Cursor, Claude Code e Codex, com revisão e testes.

Licença proprietária. Todos os direitos reservados. Consulte [LICENSE](LICENSE).
