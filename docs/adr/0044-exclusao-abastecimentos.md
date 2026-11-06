# ADR 0044, Exclusão de abastecimentos

- Status: aceito
- Data: 2026-11-04

## Decisão

Cada abastecimento na aba Posto oferece Excluir, com confirmação que identifica a compra e informa o efeito no km da Ficha. Cancelar mantém os dados. A exclusão confirmada não oferece desfazer.

O caso de uso remove a compra e refaz o trecho seguinte com as mesmas regras da edição, incluindo referências iniciais, distância, litros dos ciclos, custos, mistura e médias ponderadas. Mantém as datas, as referências do marcador e os registros anteriores. Quando uma referência de tanque cheio desaparece, os resultados que dependiam dela passam a ser estimados até existir outro ciclo completo. No trecho legado refeito, aplica o método atual sem presumir tanque cheio.

Ao excluir o registro mais recente, o km da Ficha acompanha o último registro restante apenas se ainda coincidir com o km excluído. Um km posterior ou independente é preservado. Ao excluir o único registro, mantém o km existente, pois o histórico não informa qual era o km anterior ao primeiro registro. Na ausência de períodos medidos, conserva a estimativa histórica da Ficha quando disponível; sem ela, mantém a última média conhecida como referência estimada.

Leitura, validação do registro confirmado, recálculo, substituição do histórico e atualização da Ficha ocorrem na mesma transação SQLite. Uma confirmação antiga é rejeitada e duas gravações simultâneas são bloqueadas. Falha na gravação reverte o conjunto. O aviso de alteração agenda backup e sincronização da caderneta. A calibração do marcador, derivada do histórico, perde imediatamente a referência excluída. Não há alteração de esquema ou API.
