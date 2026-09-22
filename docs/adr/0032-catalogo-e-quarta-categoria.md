# ADR 0032, Catálogo maior e a categoria Estrada

- Status: aceito
- Data: 2026-09-22

## Contexto

O catálogo tinha 54 modelos, escolhidos pelo gosto do dono: 34 trail e big trail, 14 de cidade e 6 esportivas. Faltavam motos que o brasileiro compra em volume, incluindo quatro do top 20 da Fenabrave no primeiro semestre de 2026 (Mottu Sport 110i, Shineray SHI 175 e a linha 125, Yamaha Aerox).

O campo `uso` também misturava duas ideias. O rótulo do filtro dizia "Estrada", mas o critério aplicado era a carroceria, então NXR 160 Bros, Crosser 150 e XRE 190 ficavam lá mesmo sendo motos de cidade e trabalho.

## Decisão

O filtro passa a ter quatro categorias, e `UsoCatalogo` acompanha:

- `cidade`: urbana, street pequena, scooter e trabalho.
- `trail`: trail, big trail e adventure. Era o antigo `estrada`, renomeado porque é isso que ele sempre agrupou.
- `estrada`: custom, clássica e touring de asfalto. Categoria nova, para Harley, Bonneville, Vulcan, Super Meteor, R 1250 RT, Tracer 9 e as demais que não são trail nem esportivas.
- `esporte`: carenada e naked de alta performance.

Cada categoria tem a foto de partida em `assets/catalogo/<categoria>.png`. A de `estrada` é uma custom numa estrada à noite, no mesmo clima das outras três.

Entram 62 modelos, e o catálogo vai para 116: 32 cidade, 46 trail, 16 estrada, 22 esporte. A pesquisa foi feita com agentes (seis pesquisadores por grupo de marcas e um conferente cruzando cada número com uma segunda fonte), e depois conferi à mão o que era duvidoso. O manual da SHI 175 confirmou troca de óleo a cada 1.000 km e pressão 22/28, e as Bajaj se chamam Dominar NS160 e NS200 no Brasil, não Pulsar.

`correnteKm` passa a aceitar 500, que é o que os manuais de Royal Enfield e Bajaj pedem, além dos 1.000 do resto.

## Consequências

- Os valores continuam sendo ponto de partida de uso misto. O piloto ajusta pela média dele, e o app refina sozinho a cada abastecimento (ADR 0030).
- Quem já escolheu um modelo não sente nada: a foto e os números ficam gravados no aparelho na hora da escolha.
- O filtro tem cinco botões (as quatro categorias mais Todas). Cabe em 375 px com o texto reduzido pelo `FittedBox`.
- O catálogo dobrou de tamanho, então a busca por texto no `DropdownMenu` passa a ser o caminho principal, não a rolagem.
- Ficaram de fora, por falta de fonte confiável ou por não serem vendidas no Brasil: Yamaha Factor 125 e R6, Royal Enfield Bullet 350, KTM Duke 250 e RC 390, Dafra Horizon 150 e as elétricas, que não têm consumo por litro.
- Renomear um asset exige apagar `app/build/unit_test_assets`, senão o `flutter test` segue servindo o nome antigo.
