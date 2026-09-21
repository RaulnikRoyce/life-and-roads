# ADR 0028, Primeira abertura em três passos

- Status: aceito
- Data: 2026-09-21

## Contexto

Sem ficha salva, a aba Ficha mostrava o formulário inteiro de uma vez: foto, cartão de resumo, filtro e lista do catálogo, marca, modelo, consumo com gasolina e álcool, km do painel, tanque e um "Mais números" com ano, cilindrada, pneus e personalizações. Foi o ponto mais citado pelos pilotos antigos ("muita coisa manual"). A leitura do banco em 21/09/2026 (ADR 0027) mostrou que nenhum piloto tinha sincronizado, então a primeira impressão é decisiva.

## Decisão

`PrimeirosPassos` (`features/ficha/presentation/widgets/`) substitui o formulário inicial por três perguntas, uma por tela, dentro da aba Ficha:

1. Qual é a sua moto? Filtro de uso, catálogo e marca/modelo à mão. Continuar só libera com marca e modelo.
2. Quanto marca o painel? Um campo, grande, teclado numérico.
3. Gasolina ou flex? Duas opções grandes e o consumo por litro. Álcool vazio no flex vale: o aviso mostra o número (70% da gasolina) e o Começar preenche.

Os controllers continuam sendo da tela; o widget conduz o preenchimento e chama o mesmo `_salvar()` com a validação de `FichaMoto.tentar`. Escolher no catálogo continua aplicando consumo, tanque, pneus, intervalos de óleo e corrente e a silhueta. Depois do Começar, a tela vira o painel (ADR 0025) e o resto fica em "Ajustar números". Backup e Conta ficam abaixo dos passos, porque quem trocou de aparelho precisa deles antes de qualquer pergunta.

Saíram da tela `_cartaoResumo`, `_blocoAjustar`, `_botaoSalvar` (com as fases "Salvando/Salvo") e o widget `FotoDaMoto`, que só o formulário inicial usava.

## Consequências

- Marcar Gasolina limpa o álcool (é o que faz a ficha ser "só gasolina"); marcar Flex de novo devolve o valor guardado, sem cair na estimativa.
- A estimativa de 70% é um ponto de partida declarado na tela, nunca silenciosa. O número certo vem da média do piloto, ajustada depois.
- Sem mudança de contrato, banco ou API.
- Testes: `test/unit/primeiros_passos_test.dart` (widget isolado) e `ficha vazia conduz em três passos e salva` em `widget_test.dart`.
