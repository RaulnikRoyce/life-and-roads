# ADR 0017, Refresh concorrente e reuso de token

- Status: aceito
- Data: 2026-09-17

## Contexto

Desde o ADR 0003 o refresh é de uso único. Reuso revogava todas as sessões da conta. Dois cenários legítimos caíam nessa regra.

1. As quatro abas ficam num `IndexedStack` e carregam juntas na abertura. Com o access vencido, todas recebem 401 e chamam `/auth/refresh` com o mesmo token. A primeira ganha, as outras viram "reuso" e derrubam a conta, inclusive a sessão nova.
2. Depois de trocar a senha, um aparelho que ainda não soube tenta o refresh antigo. A API tratava como roubo e revogava também o par novo do aparelho que trocou a senha. O teste de integração `troca de senha revoga refresh e emite par novo` já falhava, mas nunca rodou no CI por falta de MySQL.

## Decisão

- Coluna `sessoes.rotacionada_em` (migration `002`). Só a rotação preenche. Sair, troca de senha, exclusão e resposta a roubo revogam com `rotacionada_em = NULL`.
- Refresh já rotacionado há até `REFRESH_TOLERANCIA_SEGUNDOS` (15 s) é aceito como retry concorrente e recebe outro par, sem tocar na sessão anterior.
- Refresh rotacionado fora da janela é roubo. A API revoga todas as sessões da conta.
- Refresh revogado sem rotação responde 401 e não derruba as outras sessões.
- No app, `ApiCaderneta` mantém um único refresh em voo e reaproveita o access mais novo do storage antes de pedir outro.
- `schema.sql` fica como foto inicial do banco. Coluna nova entra só por migration, porque o `docker-compose.yml` aplica o `schema.sql` antes das migrations e um `ALTER TABLE` duplicado derrubaria o boot.
- Limiter de `/auth` pula em `NODE_ENV=test`. Testes de integração fecham o pool no `after`.

## Consequências

- Uma sessão rotacionada dentro da janela pode gerar mais de um par válido. Os pares extras vencem em 30 dias como qualquer outro.
- Um atacante que use o token nos 15 s seguintes à rotação legítima recebe um par. É o custo aceito para o app não se deslogar sozinho.
- O CI precisa de MySQL para estes testes rodarem (item separado).
