# ADR 0016, Catálogo Esportiva e silhueta local

- Status: aceito
- Data: 2026-08-26

## Contexto

O catálogo da 1.2 só tinha Cidade e Estrada. A foto da ficha só vinha da câmera/galeria. O piloto pediu esportivas comuns no BR e uma foto do modelo ao escolher no catálogo.

## Decisão

- `UsoCatalogo.esporte` e segmento **Esportiva** (CBR 500R, CB 500F, R3, MT-03, Ninja 400, Duke 390). Sem FIPE, sem placa.
- Quatro silhuetas originais em `assets/catalogo/` (cidade, estrada, esporte, scooter). Desenho nosso, sem foto de fabricante.
- Ao escolher o modelo, copiar o asset para `FotoMoto` neste aparelho. O piloto troca depois. Nada na API.

## Consequências

- Recorte intacto. Flex continua com álcool nos modelos que já eram flex. Onda UX 13–15 fechada.
