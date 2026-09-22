# ADR 0030, Abas Posto e Viagem, e o consumo entre abastecimentos

- Status: aceito
- Data: 2026-09-21

## Contexto

A aba Viagem juntava a calculadora de viagem com o registro de abastecimento, e o Mapa ficava numa aba à parte. O Raulnik apontou que abastecer é rotina de posto, não coisa de viagem, e que o trajeto no mapa e o cálculo da viagem pertencem à mesma tarefa.

O consumo também estava errado na origem. Cada abastecimento usava o km da Ficha como referência (que podia ser o digitado na primeira abertura) e gravava na Ficha o consumo daquele único intervalo, então o número pulava a cada posto.

## Decisão

Quatro abas: **Ficha, Manutenção, Posto, Viagem**.

- **Posto** (`features/viagem/presentation/tela_posto.dart`, a pasta continua `viagem` porque os cálculos moram lá): painel com o custo por km real em número grande, pastilhas de postos, consumo e tanque cheio, o combustível que vale mais hoje e um gráfico desenhado à mão do custo por km posto a posto; cartão de abastecimento com os preços do dia, "Registrar abastecimento" em folha e os postos em linhas.
- **Viagem** (`features/mapa/presentation/tela_mapa.dart`, a classe continua `TelaMapa`): o mapa em tela inteira com um cartão flutuante translúcido na base. Recolhido, tem Rastrear, Onde estou e Traçar trajeto; aberto, tem os km da viagem (do trajeto ou digitados), gasolina ou álcool, Calcular e o bilhete com litros, valor e se cabe no tanque. Os preços vêm do Posto, pelo estado do `ViagemController` (`definirPrecos`).
- `core/widgets/folha_oficina.dart` é a folha padrão (puxador, tema dos campos sobre o fundo da folha, guarda de toque duplo, fecha só se a rota ainda é a de cima). A Manutenção ainda usa a própria `_abrirFolha`, porque precisa do gancho que redesenha a folha quando a sync chega; unificar fica para depois.

Consumo entre abastecimentos (`domain/usecases/montar_abastecimento.dart`):

- A referência de km é o **abastecimento anterior**, não a Ficha. O primeiro registro só guarda km do painel, litros e valor, sem consumo; o app avisa que a partir do próximo calcula.
- Do segundo em diante, km rodados = km do painel agora menos o km do posto anterior; consumo = km rodados por litro abastecido agora (tanque cheio nos dois). As faixas de sanidade continuam (até 2.000 km, entre 5 e 80 km com 1 L).
- Numa moto flex, o intervalo foi rodado com o combustível que **estava no tanque**, o do abastecimento anterior, e é para ele que o consumo conta (`combustivelDoIntervalo`). A linha do posto diz "rodou com álcool" quando difere do abastecido.
- A Ficha recebe a **média ponderada** de todos os intervalos daquele combustível, soma dos km dividida pela soma dos litros (`mediaKmPorLitro`), que se refina a cada abastecimento e alimenta a Viagem e o alcance.
- Sem migration no banco do aparelho: as colunas continuam obrigatórias e o primeiro registro grava zero em km rodados, consumo e custo por km; `RegistroAbastecimento.temConsumo` diz se há intervalo. Custo médio e gráfico ignoram registros sem intervalo. Registros antigos e backups continuam válidos.

## Consequências

- Quem já tinha histórico não perde nada; o próximo abastecimento passa a usar o último registro como referência.
- O primeiro abastecimento não mostra consumo, e a tela diz isso ("primeiro registro"). Com um só intervalo, o painel diz "pelo último intervalo".
- Abastecer sem encher o tanque distorce o consumo daquele intervalo, como em qualquer caderneta por tanque cheio. Fica na copy da folha.
- `StatOficina` saiu de `tema.dart` (ficou sem uso). `CreditoOsm` ganhou alinhamento para o crédito do OpenStreetMap não ficar atrás do cartão flutuante.
- README e `CLAUDE.md` passam a listar as abas novas. Os testes de widget usam `_aba('Posto')` e `_aba('Viagem')`.
