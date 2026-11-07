# 0050. Versões de sincronização e confirmação de gravações

Data: 06/11/2026. Estado: implementado localmente, ainda sem publicação.

## Contexto

A auditoria reproduziu confirmação antiga limpando a pendência de uma edição posterior, carimbos iguais para alterações no mesmo segundo, descarte de alteração durante backup lento e consumo positivo aceito pela API que excedia DECIMAL(5,2).

## Decisão

Ficha e agenda passam a confirmar metadados somente para a versão local enviada, com conferência e gravação na mesma transação SQLite. Versões locais da ficha avançam em segundos inteiros porque essa é a precisão do DateTime já persistido no Drift; são identificadores de edição e podem ficar à frente do relógio durante uma sequência de alterações. A versão remota completa da ficha fica também na tabela KV, preservando milissegundos sem trocar a codificação de colunas antigas. A agenda já usa texto ISO. Controllers descartam respostas de salvamentos anteriores.

As migrations 006 e 007 acrescentam `atualizado_em_ms` a ficha e manutenção. Linhas antigas continuam com a versão derivada do timestamp anterior até a primeira escrita. A API retorna a versão como `atualizadoEm`, no mesmo formato ISO UTC existente, e escolhe o maior entre o relógio atual e a versão anterior mais um milissegundo. O valor identifica uma versão; não promete um instante exato do relógio.

O novo header opcional `X-Base-Atualizado-Em` leva a versão conhecida ou a string `null`, para exigir ausência de registro. A API bloqueia a linha da conta, confere a versão e grava dentro de uma transação MySQL, inclusive na criação. Base diferente retorna 409 sem alterar os dados. Bloquear a conta simplifica a primeira gravação, com o custo de serializar ficha e agenda da mesma conta. SQL usa apenas os dois nomes de tabela fixos definidos no código, nunca valores da requisição.

A ausência do header mantém compatibilidade com clientes antigos e preserva sua semântica de sobrescrita. A proteção completa exige API e app atualizados; publicar a API primeiro. Escolher manter o aparelho busca a versão atual antes de tentar gravar, sem desabilitar a conferência de concorrência. O corpo Zod permanece estrito, sem campos novos.

O backup automático registra nova alteração durante a escrita e faz outra exportação ao terminar. Há um único escritor. O descarte impede repetição e notificação depois de liberar os notifiers.

A migration 008 troca somente `km_litro` e `km_litro_alcool` por DOUBLE, alinhando o armazenamento ao `number` finito da API e ao `double` do app. Consumo é estimativa, não valor monetário. Valores pagos, litros e preços mantêm seus tipos. Não foi introduzido teto comercial; testes incluem os extremos finitos de number e a leitura efetiva do MySQL.

## Validação e implantação

Regressões cobrem resposta antiga, backup lento e falho, descarte, SQLite reaberto, preservação de milissegundos, conflito por header, criação/atualização paralela, relógio parado, clientes sem header e consumo persistido. Migrations são testadas somente em banco descartável.

Nenhuma versão de app foi incrementada e nenhum APK foi gerado. Atualizar o relatório da auditoria com os resultados antes de commit ou publicação. Atualizar a API antes de distribuir app/web; clientes antigos continuam sem conferência de versão até serem atualizados.
