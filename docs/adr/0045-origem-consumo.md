# ADR 0045, Identificação da origem do consumo

- Status: aceito
- Data: 2026-11-04

## Decisão

A apresentação identifica referência inicial, estimativa pela Ficha, medição entre tanques cheios, medição com mistura, método anterior e medição indisponível. Marcar tanque cheio, isoladamente, não transforma um registro em medição: os totais válidos do ciclo continuam necessários.

O painel identifica separadamente a origem do custo do histórico e da média de gasolina. O custo pode incluir ciclos com mistura, que são contados e informados, enquanto a média medida de gasolina usa apenas os ciclos completos sem mistura atribuídos a ela. A autonomia com tanque cheio e os litros e valores da viagem são identificados como estimativas.

O histórico separa litros e valor da compra dos quilômetros, litros e custo do ciclo medido. Parciais mostram distância desde o anterior, referência de consumo e custo estimado, sem sugerir que os litros comprados sejam o volume consumido no intervalo. Ciclos com mistura não recebem um único combustível no texto do período. Os registros legados não presumem abastecimento parcial.

O caso de uso de identificação é derivado dos dados existentes. Não altera fórmulas, médias, persistência, backup ou API, nem atribui percentuais de confiança à medição.
