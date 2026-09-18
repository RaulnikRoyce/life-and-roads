# ADR 0023, UI viva

- Status: aceito
- Data: 2026-09-18

## Contexto

O app funcionava mas não reagia: troca de aba cortava seco, salvar não dava retorno além do snackbar, números apareciam prontos, o carregamento era um spinner genérico no centro. A identidade visual (paleta oficina, tipografia condensada, botões grandes) estava boa e não era o problema.

## Decisão

Movimento só onde confirma ação ou dá hierarquia, com `flutter/animation` puro, sem pacote novo. Tudo em `core/widgets/movimento.dart`:

- `Movimento.curto/medio/longo` (180, 320, 480 ms) e uma curva só (`easeOutCubic`).
- **Troca de aba**: `FadeTransition` + `SlideTransition` por cima do `IndexedStack`, controlados por um `AnimationController` na tela principal. O stack não muda de chave, então o estado das quatro telas continua vivo.
- **Abertura**: logo entra com escala 0,85 → 1 e fade; o crédito entra por `EntradaSuave`.
- **Esqueleto** (`Esqueleto`) no lugar do spinner em Ficha, Manutenção e Viagem, com um pulso só; o conteúdo entra com `EntradaSuave` (fade + deslize de 12 px).
- **Números que contam** (`NumeroAnimado`, `StatOficina.numero`): painel e km/l no cartão da moto, litros e reais no resultado da Viagem.
- **Botão Salvar** com três estados (Salvar ficha, Salvando, Salvo com ✓ por 1,2 s), trocando por `AnimatedSwitcher`.
- **Pulso** (`Pulso`) no sininho quando chega aviso novo e no ícone da linha de sync ao começar e ao terminar.

Regras: nada em loop infinito (bateria, e `pumpAndSettle` dos testes trava), nada que atrapalhe leitura no sol ou toque com luva, sem Lottie/Rive.

## Consequências

- Nenhum teste mudou: textos e estrutura são os mesmos, só entram animados.
- Hierarquia da Ficha (cartão da moto como herói, seções secundárias mais neutras) e estados vazios com ilustração ficam para uma fase de desenho, a ser mostrada no navegador antes.
