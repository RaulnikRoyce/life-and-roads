# ADR 0034, app web na tela inicial como caminho de iPhone

- Status: aceito
- Data: 2026-09-22

## Contexto

Os pilotos são de Android e o recorte diz iOS fora. Apareceu a vontade de ver o app num iPhone, e o caminho nativo cobra três coisas antes de entregar qualquer valor. Um Mac, porque o Xcode só existe em macOS. US$ 99 por ano da Apple, cobrados sempre, contra os US$ 25 uma vez da Play. E a criação da pasta `ios/` inteira, com `Info.plist`, textos de permissão, notificações Darwin e um substituto para a MediaStore, que não existe no iPhone.

O build web já existia e já rodava, com o Drift em `sqlite3.wasm` e a caderneta persistindo no navegador. Faltava acabamento, não fundação.

O medo que quase derrubou a ideia foi o Safari apagar dado de site depois de 7 dias sem uso, o que seria fatal para uma caderneta. Adicionar à tela inicial isenta o app dessa limpeza, por regra documentada da Apple, e é isso que torna a escolha defensável.

## Decisão

O app web publicado no GitHub Pages passa a ser o caminho de iPhone, instalado pela opção "Adicionar à Tela de Início" do Safari. Custo zero, porque o repositório é público.

O endereço é **`app.raulnikroyce.dev`**, domínio próprio apontado por CNAME para o GitHub, que emite o certificado. O domínio raiz fica livre para o portfólio, e o app acompanha o `api.raulnikroyce.dev` que já existe. No Cloudflare o registro precisa ficar **sem proxy**, cinza, porque com o proxy ligado o GitHub não consegue emitir o certificado. Como o app fica na raiz do domínio, o build usa `--base-href /`.

Um job `pages` no CI compila e publica, disparado por tag `v*` junto com o APK, para manter a mesma disciplina, e por botão manual, para publicar um teste sem cortar versão. O `manifest.json` e os ícones deixam o padrão do Flutter e passam a usar a marca, com o fundo `#121212` que o Android já usa na abertura. O `index.html` recupera `apple-mobile-web-app-capable`, que some nos modelos novos do Flutter e ainda é o caminho garantido nos Safari anteriores ao 15.4.

Isto **não** põe iOS no recorte. App web já existia como plataforma. O que muda é que ele deixa de ser ferramenta de desenvolvimento e vira coisa que piloto usa, e por isso vira decisão registrada.

## O que o piloto perde no app web

- **Lembrete de manutenção por notificação do sistema.** O `flutter_local_notifications` não tem lado web, e notificação web no iPhone só existe do iOS 16.4 em diante. Os avisos continuam dentro do app, no anel de saúde e no sininho.
- **Backup automático em pasta fixa.** Depende da MediaStore do Android (ADR 0033). No navegador só existe oferecer o download, com o piloto confirmando.
- **Funcionar sem internet.** Desde o Flutter 3.44 o Flutter parou de gerar o service worker, e o que ele gera hoje só desinstala o antigo. Offline virou trabalho nosso e ficou fora desta ADR. Exige service worker escrito à mão e as fontes Oswald e Source Sans 3 embutidas como asset, porque hoje o `google_fonts` busca elas na rede.

## Consequências

- A caderneta passa a morar em **dois lugares separados**, o app Android e o app web. Não conversam. Quem usar os dois começa do zero no segundo, a menos que exporte o backup de um e importe no outro.
- A API precisa aceitar a origem nova. É a variável `CORS_ORIGIN` no Render, que `api/src/app.ts` já lê, sem mudança de código.
- O bloco de backup na Ficha passou a ter três textos em vez de dois. Sem pasta Download, que é o caso do iPhone e do navegador, ele para de prometer a cópia automática, porque ali ela não acontece. A fonte única disso é `PastaDownload.disponivel`.
- Enviar backup funciona no iPhone. Sem arquivo em disco, o app compartilha o JSON como texto, e o Safari aceita. Se falhar, sobra o Copiar backup.
- A primeira abertura baixa cerca de **4 MB** comprimidos, sendo 2,9 MB do motor gráfico CanvasKit e 1,2 MB do app. Com banco e imagens do catálogo, 5,6 MB.
- O GitHub Pages precisa ficar como "GitHub Actions" na configuração do repositório, passo manual e uma vez só.
- O endereço é público. Qualquer um abre e usa como caderneta local. Não expõe dado de ninguém, porque sem conta nada sai do aparelho, e com conta vale a mesma autenticação da API.
- O desempenho em aparelho antigo é incógnita. No iOS o Flutter sempre cai no caminho CanvasKit, porque nenhum navegador de iPhone tem WasmGC. O primeiro teste é num iPhone 6s, de 2015.
- Fica registrado que o **iPhone 6s para no iOS 15.8.8** e o **Flutter 3.47 já exige iOS 15**. Mesmo no caminho nativo, esse aparelho está no último degrau que funcionaria.
