# ADR 0048, Referência de consumo após excluir uma medição

- Status: aceito
- Data: 2026-11-06

## Decisão

Cada novo abastecimento preserva as referências de gasolina e álcool anteriores às medições do histórico. Os campos opcionais referenciaGasolina e referenciaAlcool acompanham o JSON de detalhes já utilizado no SQLite, nos backups e na caderneta cifrada. Não há migração de tabela nem mudança das rotas da API.

Editar ou excluir registros utiliza essas referências quando não resta um ciclo medido. A medição removida deixa de alimentar a estimativa da Ficha e o alcance. O primeiro abastecimento continua sem consumo medido e com kmPorLitro em zero.

O caso reproduzido começa com referência de 45 km com 1 L, registra dois tanques cheios e mede 40 km com 1 L. Depois de corrigir os litros, mede 50. Excluir o fechamento deve restaurar a referência de 45 e retirar a medição, sem manter 50 como estimativa.

Históricos anteriores continuam aceitos. Quando há um registro estimado antigo, ele oferece a referência compatível já usada pelo app. Se não há referência preservada nem estimativa anterior, o valor original não pode ser reconstruído com segurança e o comportamento anterior é mantido. Clientes antigos podem descartar os campos opcionais ao regravar os registros.
