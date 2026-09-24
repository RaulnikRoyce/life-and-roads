# ADR 0036, boas-vindas no cadastro e remetente que aceita resposta

- Status: aceito
- Data: 2026-09-24

## Contexto

Os e-mails de recuperação de senha caíam no spam do Gmail. O diagnóstico teve três partes, pelo relatório do Resend e pelo cabeçalho do próprio Gmail.

- **DMARC.** O registro não existia quando os primeiros e-mails saíram, e o Gmail nem chegava a avaliar. O Raulnik criou `v=DMARC1; p=none` em 23/09, e o primeiro e-mail depois disso passou em SPF, DKIM e DMARC e caiu na caixa de entrada. A autenticação funciona porque o DKIM é assinado por `raulnikroyce.dev`, o mesmo domínio do remetente.
- **Google Fonts.** O modelo buscava as fontes fora do domínio, o Gmail ignora e ainda conta como sinal de spam. Tirado no commit `147897f`.
- **`no-reply`.** Remetente que não aceita resposta tira do destinatário o jeito de falar com quem mandou, e o filtro lê isso como sinal ruim. O domínio não recebia e-mail nenhum, então trocar por outro endereço devolveria erro a quem respondesse.

Depois disso veio o pedido de mandar uma boas-vindas quando o piloto cria a conta.

## Decisão

**O domínio passa a receber e-mail.** Email Routing do Cloudflare, de graça, com três MX na raiz e o SPF do Cloudflare na raiz. Existe um endereço só, `contato@raulnikroyce.dev`, encaminhado para o Gmail do Raulnik sem expor ele. Não há catch-all, para não atrair spam de gente chutando nome. Os registros do Email Routing não se cruzam com os do Resend, que manda pelo subdomínio `rsend.` com DKIM próprio em `resend._domainkey`.

**Os e-mails do app saem de `contato@`.** O `EMAIL_REMETENTE` do Render e o padrão no código foram trocados juntos, em 24/09.

**A boas-vindas sai uma vez, no cadastro, sem esperar o Resend.** Mesmo padrão da recuperação: dispara e segue, e se falhar a conta existe do mesmo jeito e o erro fica no log só com o número da conta. O texto responde as três perguntas de quem acabou de se cadastrar. O que a conta guarda, a ficha e as datas de manutenção. O que continua só no celular, abastecimentos, fotos e pinos, com o caminho do Enviar backup. E como voltar se esquecer a senha. Termina convidando a responder.

**A moldura dos e-mails virou uma peça só**, `api/src/shared/email/moldura.ts`, com fundo, faixa, logo, marca e rodapé. O modelo do código passou a usar ela, e o HTML dele saiu idêntico byte a byte ao de antes.

## O que ficou de fora

**Confirmação de e-mail.** O cadastro continua aceitando qualquer endereço sem confirmar. Com a boas-vindas, um endereço digitado errado ou de outra pessoa faz o servidor mandar mensagem para quem não pediu, e e-mail que volta ou que vira reclamação de spam derruba a reputação do domínio. No beta, com poucos cadastros, o risco é pequeno, e a confirmação mudaria a tela de cadastro no app e exigiria release nova das duas plataformas. A mitigação é a última frase da boas-vindas, que dá a quem recebeu por engano um jeito de pedir a exclusão em vez de apertar spam. Se o painel do Resend mostrar e-mail voltando, a confirmação passa a valer o custo.

## Consequências

- Todo cadastro passa o e-mail do piloto ao Resend, não só quem pede recuperação. `docs/privacidade.md` ganhou o parágrafo, e a declaração de dados da Play precisa refletir isso quando o app for para a loja.
- **Pedido de exclusão chega por e-mail e é atendido à mão**, no banco de produção, pelo Raulnik. Deve ser raro, mas a boas-vindas promete.
- O que o piloto responder fica na caixa do Gmail do Raulnik, fora do servidor.
- Os testes de banco passaram a separar os e-mails pelo assunto, porque a boas-vindas também cai na caixa falsa. Quatro deles contavam todos os e-mails e quebrariam sem isso.
- O contrato de `/auth/registrar` não mudou. Mesma entrada, mesma resposta.
- Ainda vale ligar o **Gerenciamento de DMARC** do Cloudflare. O `rua` atual aponta para o Gmail, que não aceita relatório de outro domínio, então os relatórios nunca chegam.
