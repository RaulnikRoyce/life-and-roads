# 0040. Abastecimentos parciais e consumo medido

Decisão de 30/10/2026, a pedido do Raulnik. Aplicada sobre a base 1.5.0+10.

Cada compra registra km, litros e valor pago ou preço por litro. O primeiro registro estabelece referência. Parciais apresentam estimativa pela média da Ficha, sem substituir essa média por distância dividida pelos litros comprados. O km inicial continua no cadastro; depois, o painel é atualizado na aba Posto.

O piloto informa quando completou o tanque. Dois registros cheios delimitam a medição, incluindo todos os litros comprados depois do primeiro até o segundo. Os litros do primeiro são excluídos. A média da Ficha é ponderada pelos volumes de períodos medidos. O combustível do fechamento não é atribuído retroativamente ao trecho rodado. Se houve troca de combustível nos parciais, o ciclo é identificado como mistura e não substitui médias específicas.

Resultados positivos e finitos não têm teto de consumo nem restrição de plausibilidade de distância. O odômetro deve avançar, respeitando o limite existente do painel. O contrato da ficha passa a aceitar consumo positivo sem o teto de 80. Sem publicar a API atualizada, o servidor antigo continua recusando médias acima desse teto.

As barrinhas são opcionais e configuráveis pelo total de segmentos, com leituras antes e depois. São observações para calibração futura, sem conversão linear em litros nem promessa de consumo medido por barras. Essa primeira etapa não implementa calibração automática.

SQLite passa da versão 2 para 3, acrescentando detalhes JSON opcionais em cada abastecimento. Linhas antigas permanecem como legado e não iniciam ciclos de tanque cheio. Os novos campos acompanham JSON, backup local e caderneta na conta, cujo contrato já permite campos adicionais nos itens. Clientes antigos podem perder os novos detalhes se restaurarem e reenviarem o histórico; por isso Android e web devem ser atualizados juntos antes de usar a conta para alternar entre eles.

O limite local sobe de 20 para 5000 registros, alinhado ao limite da conta, para preservar ciclos longos de parciais. O limite de tamanho do pacote da nuvem continua valendo. Km e compra são gravados na mesma transação local, antes da sincronização. O aviso de mudança da caderneta e a atualização da Ficha continuam ativos.
