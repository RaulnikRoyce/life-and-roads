# ADR 0043, Calibração do marcador por observações

- Status: aceito
- Data: 2026-11-04

## Decisão

A aba Posto oferece uma consulta recolhível do combustível pelas barrinhas. O piloto escolhe o total de segmentos e a leitura atual. Cada nível aprende separadamente, sem divisão uniforme do tanque, interpolação entre níveis ou afirmação de que zero barras significa vazio.

A referência é a capacidade nominal informada na Ficha. Em uma compra marcada como tanque cheio, com o marcador final no máximo, a capacidade menos os litros comprados estima o volume anterior. São exigidos três registros distintos no mesmo nível antes de mostrar a faixa mínima e máxima observada. Esse mínimo é uma regra de liberação da consulta, sem significado estatístico de confiança. A faixa não é um intervalo de confiança nem garante combustível disponível. Inclinação, sensor, volume nominal e enchimento afetam a estimativa. Compras parciais não viram referências absolutas.

Registros repetidos não contam como novas observações. Compras com litros incompatíveis com a capacidade são ignoradas apenas na calibração. Leituras com ordenação inteiramente invertida entre níveis suspendem a consulta até correção dos dados. A compra continua registrada normalmente.

Cada novo abastecimento guarda uma referência opcional do marcador, composta por marca, modelo, ano, cilindrada e capacidade da Ficha. A calibração também separa os totais de barras. Históricos antigos sem essa referência não são atribuídos retroativamente à moto atual. A edição preserva a referência original em todo o trecho refeito. As faixas são derivadas do histórico e se atualizam quando ele é corrigido ou restaurado.

A referência acompanha os detalhes JSON já existentes no SQLite, no backup e na caderneta cifrada. Não exige migração nem alteração da API. Clientes antigos podem perder esse campo se regravarem o histórico. O consumo medido entre tanques cheios permanece separado da estimativa do marcador; não se usa a faixa para produzir consumo supostamente medido em parciais.
