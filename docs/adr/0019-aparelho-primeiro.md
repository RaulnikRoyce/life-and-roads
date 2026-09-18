# ADR 0019, Aparelho primeiro, servidor por trás

- Status: aceito
- Data: 2026-09-18

## Contexto

A API de produção roda no plano grátis do Render, que hiberna após 15 min sem tráfego e leva ~20 s para acordar. As telas Ficha e Manutenção mostravam só um spinner até o GET do servidor voltar, com timeout de 8 s. Com conta, toda primeira abertura depois de uma pausa era 8 s de bolinha seguida de "API fora do ar", e a fila local ficava `failed`.

## Decisão

- `FichaRepository.carregarLocal()` e `ManutencaoRepository.carregarLocal()` devolvem só o que está no aparelho, sem rede.
- Os controllers mostram o local na hora (`carregando` só quando não há nada no aparelho) e, com conta, seguem para `carregar()` por trás com `sincronizando = true`. As telas mostram um `LinearProgressIndicator` de 2 px enquanto isso.
- Um contador de geração no controller descarta o resultado da sincronização se o piloto salvou no meio, para o GET antigo não sobrescrever o que ele acabou de gravar.
- `ApiCaderneta.aquecer()` dispara `GET /health` na abertura do app, sem esperar, **só quando há token** (sem conta, nada sai do aparelho).
- Timeout de 25 s até a primeira resposta HTTP da sessão; 8 s depois disso. Ninguém fica bloqueado pelos 25 s porque a tela já está com o local.

## Consequências

- O piloto vê a caderneta em menos de um segundo, com ou sem rede.
- Enquanto a API acorda, o traço de progresso fica visível por até ~20 s. É honesto sobre o que está acontecendo.
- Um monitor externo batendo em `/ready` (fora do código) evita a hibernação e faz o traço durar milissegundos.
