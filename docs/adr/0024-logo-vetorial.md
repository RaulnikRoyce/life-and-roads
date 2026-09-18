# ADR 0024, Logo vetorial e abertura desenhada

- Status: aceito
- Data: 2026-09-18

## Contexto

A abertura mostrava o PNG da logo aparecendo com fade. O piloto pediu algo à altura da marca. O Raulnik exportou o emblema do CorelDRAW em SVG (texto em curvas, sem bitmap, 31 caminhos, só M/L/C/Z).

## Decisão

- `core/marca/logo_dados.dart` é gerado do SVG por script (coordenadas normalizadas para largura 1000), com os caminhos agrupados por função: disco, borda, capacete esquerdo, capacete direito, cabelo, fitas, textos, Instagram, arroba, cidade. Não se edita à mão.
- `LogoPintor` desenha a logo num progresso `t` de 0 a 1: os contornos dos capacetes e do cabelo se traçam (`PathMetrics.extractPath`), os preenchimentos surgem, o disco abre em círculo, as fitas deslizam, o rodapé aparece. Em `t = 1` é o emblema completo. Leitor de caminho próprio de 20 linhas; sem `flutter_svg`, `path_drawing`, Lottie ou Rive.
- `LogoMarca` (parado) na barra superior e `LogoAnimada` na abertura, ligados por `Hero`: a abertura empurra a rota das abas com fade e a logo voa para a barra.
- Tema vira `temaProvider` (Riverpod) para a tela principal reagir à troca de tema mesmo tendo entrado por rota.
- `assets/lr.png` sai da lista de assets do app (848 KB a menos no APK); continua como fonte do ícone do Android em tempo de build.

## Consequências

- A logo em tela é nítida em qualquer tamanho e pesa 59 KB de texto.
- Se a logo mudar, regenerar `logo_dados.dart` a partir do SVG novo (o script de geração vive fora do repositório; o cabeçalho do arquivo diz como foi feito).
