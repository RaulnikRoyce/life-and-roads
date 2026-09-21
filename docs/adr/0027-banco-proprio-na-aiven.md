# ADR 0027, Banco próprio na Aiven

- Status: aceito
- Data: 2026-09-21

## Contexto

O serviço MySQL da Aiven (plano grátis, um por conta) é compartilhado com outro projeto do Raulnik, o Beco Underground. Os dois apontavam para o mesmo banco, `defaultdb`. Como o Beco já tinha uma tabela `usuarios` (com `perfil ENUM('admin','produtor')` e sem `criado_em`), a migration `000_usuarios.sql` do life.and.roads, que usa `CREATE TABLE IF NOT EXISTS`, não criou nada e foi marcada como aplicada. As demais migrations criaram `fichas`, `manutencoes`, `localizacoes`, `sessoes` e `eventos_cliente` com chave estrangeira para a `usuarios` do Beco.

Efeitos, descobertos na leitura do beta em 21/09/2026:

- Cadastro no app criava um usuário do Beco com `perfil = 'produtor'`, o padrão da coluna, com acesso à API do Beco.
- Uma conta do Beco logava no app.
- `ON DELETE CASCADE` faria os dados do piloto sumirem se o Beco apagasse o usuário.
- O backup semanal (ADR 0020) levava as 17 tabelas dos dois projetos.

Nenhum piloto tinha criado conta ou sincronizado (zero fichas, zero sessões), então não havia dado do life.and.roads a preservar.

## Decisão

Cada projeto tem o seu banco dentro do mesmo serviço da Aiven. O life.and.roads usa o banco `life_and_roads`, criado em 21/09/2026 pelo painel da Aiven (Service, Databases, Create database). `DB_NAME` no Render e no secret do GitHub passou de `defaultdb` para `life_and_roads`. O deploy seguinte rodou as sete migrations num banco vazio, com a `usuarios` do repositório.

As seis tabelas que o life.and.roads tinha deixado no `defaultdb` (`fichas`, `manutencoes`, `localizacoes`, `sessoes`, `eventos_cliente`, `schema_migrations`) foram apagadas pelo Raulnik, com o `DROP` escrito e conferido antes. A `usuarios` do Beco não foi tocada.

## Consequências

- Nunca apontar dois projetos para o mesmo banco. Um serviço MySQL comporta vários bancos, e é assim que se divide.
- `CREATE TABLE IF NOT EXISTS` em migration não avisa quando a tabela já existe com outra forma. Uma migration futura que dependa de coluna pode falhar em silêncio; conferir com `SHOW COLUMNS` quando um banco novo for ligado.
- O backup passou de 4,9 KB para 1,8 KB, só com as tabelas do produto. A checagem de sanidade (cinco `CREATE TABLE` ou mais) passa com as sete tabelas próprias.
- Quem tinha conta de teste no app (a conta do Raulnik, criada no `defaultdb`) precisa cadastrar de novo.
- Consulta de leitura do beta, sem e-mail: contagens de `usuarios`, `fichas`, `manutencoes`, sessões vivas e `eventos_cliente` por versão. Rodar com o cliente `mysql` e `-p` sem valor, para a senha não ir para o histórico.
