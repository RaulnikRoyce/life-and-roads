# ADR 0042, Edição de abastecimentos

- Status: aceito
- Data: 2026-10-30

## Decisão

Cada compra no Posto oferece edição de km, litros, valor pago, combustível, tanque cheio e marcador. O valor pago é obrigatório na edição e determina o preço por litro. A data e a posição no histórico são preservadas; o km precisa respeitar os registros vizinhos.

O caso de uso refaz a compra corrigida e as posteriores, incluindo distância, ciclos entre tanques cheios, custos, mistura e médias por combustível. Os registros anteriores são mantidos. Registros do método antigo no trecho refeito usam o método atual, sem presumir tanque cheio. Sem ciclo medido, o resultado é estimado; usa a estimativa mais antiga disponível para o combustível, ou a média da Ficha quando não existe essa referência.

Histórico e Ficha são gravados na mesma transação SQLite. A correção do último km acompanha a Ficha, preservando um km da Ficha que já fosse posterior ao histórico. Backup e sincronização da caderneta recebem o aviso de alteração. Uma edição aberta sobre um registro já modificado é rejeitada. Não há mudança no formato do backup nem na API.
