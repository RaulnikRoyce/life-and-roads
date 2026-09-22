# ADR 0033, Backup automático e convite de conta

- Status: aceito
- Data: 2026-09-22

## Contexto

Três pedidos dos pilotos depois da 1.3.0:

1. O backup só acontecia se o piloto lembrasse de apertar Enviar. Pediram um caminho fixo no celular, salvando sozinho.
2. Pediram conta obrigatória, para coletar dados desde o primeiro uso.
3. Com 116 modelos, pediram uma busca no catálogo, porque a lista rolando não serve mais e ninguém descobria que dava para digitar.

## Decisão

**Backup automático.** A cada mudança que vale (ficha, manutenção, abastecimento) o app regrava `Download/life.and.roads/caderneta.json`. Espera três segundos antes de gravar, porque salvar acontece em rajada, e falha em silêncio.

O caminho fixo pedido não existe como "sem pedir nada" desde o Android 11. A pasta privada do app seria automática, mas some ao desinstalar, que é justamente quando o backup importa. Então o app usa a **MediaStore** do próprio Android, que é a forma sancionada de escrever em `Download` sem permissão. São 90 linhas de Kotlin em `GravadorDownload.kt` falando direto com a API do sistema, sem plugin de terceiro: os dois que existem no pub.dev estão abandonados ou com adoção mínima. Fora do Android o canal devolve null e o resto do app segue.

**Conta continua opcional.** Obrigar cadastro na primeira abertura cobraria internet, e-mail e senha antes de o piloto ver qualquer coisa, e o servidor hiberna, então a primeira chamada leva uns 20 segundos, bem na hora do cadastro. Também mudaria o recorte do projeto e a declaração de dados na Play. Em vez disso, o convite aparece **depois** da ficha preenchida, quando existe o que perder, e some para sempre se o piloto dispensar.

Ao dispensar, o app pergunta o motivo, com quatro respostas de um toque e um campo livre. Responder é opcional. O texto vai pela rota anônima que já existe para crash (`POST /monitor/evento`, tipo novo `conta_recusada`), sem e-mail, sem id e sem nada da caderneta.

**Busca no catálogo.** Um campo com lupa abre uma folha com o cursor já no campo, categorias em fichas e a lista mostrando cilindrada, tanque e consumo. A busca ignora acento e aceita pedaços em qualquer ordem.

## Consequências

- O arquivo em `Download` é visível no gerenciador de arquivos e sobrevive a desinstalar o app, de propósito. Quem pegar o celular desbloqueado lê a caderneta, o mesmo que já valia para qualquer arquivo exportado.
- O nome do arquivo é sempre o mesmo, e a gravação regrava por cima, para não virar `caderneta(1).json`.
- O carimbo do último backup aparece na Ficha. Se gravar o carimbo falhar, o backup continua valendo.
- Este projeto passa a ter código nativo. O build de depuração compila nesta máquina desde 22/09/2026 (Android Studio instalado), então dá para conferir o Kotlin antes de subir.
- `docs/privacidade.md` ganhou o backup automático e o motivo de recusa.
- O contrato de `/monitor/evento` aceita um `tipo` a mais. Nada existente mudou.
