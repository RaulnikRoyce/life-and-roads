# Privacidade, life.and.roads

Última atualização, 2026-09-24.

A caderneta vive **neste aparelho**. A conta é opcional.

## O que o servidor guarda

Com login, e-mail, senha (bcrypt), ficha (sem PSI), datas de manutenção, o último ponto GPS, a versão dos termos que você aceitou com a data do aceite e, cifrada, a caderneta na conta. Refresh token só como hash.

Ficam só no aparelho a foto, o arquivo de backup, placa, chassi e RENAVAM. Com a caderneta na conta desligada, ficam também os abastecimentos, os serviços, os pinos, o PSI, o km de óleo e corrente, a validade da CNH e os preços do dia.

## Caderneta na conta

Com conta e o interruptor ligado, que é o padrão, o app manda para o servidor os abastecimentos, os serviços, os pinos, o PSI, o km de óleo e corrente, a validade da CNH e os preços do dia. A foto nunca vai. Serve para a caderneta voltar num celular novo ou no app web, e a base é a execução do serviço que a conta oferece (LGPD, art. 7º, V).

O servidor guarda esse conteúdo cifrado com AES-256-GCM, com uma chave que só ele tem, amarrada à sua conta. Quem lê o banco vê bytes embaralhados. A chave fica no servidor, e não no seu celular, para a recuperação de senha por e-mail continuar devolvendo a caderneta.

O app manda sozinho, alguns minutos depois de uma mudança ou quando sai de cena. Desligar o interruptor, em Ficha, Conta, apaga a cópia do servidor e para os envios deste aparelho. Se você usa a mesma conta em outro celular, desligue lá também.

Quem já tinha conta antes desta versão vê um aviso no topo da Ficha, e nada sobe até responder.

Backup automático, **só no app de Android**: a cada mudança na caderneta o app grava uma cópia em `Download/life.and.roads/caderneta.json`, no próprio aparelho. Esse arquivo fica visível no gerenciador de arquivos e sobrevive a desinstalar o app, de propósito, para o piloto não perder a caderneta ao trocar de celular. Nada é enviado; quem decide compartilhar é o piloto, pelo botão Enviar backup.

No app web instalado na tela inicial não existe essa cópia automática, porque o navegador não escreve em pasta do aparelho sem o piloto confirmar. Ali a caderneta fica guardada dentro do próprio navegador e sai só pelo botão Enviar backup. Vale saber que apagar os dados do site, ou o app da tela inicial, apaga a caderneta junto.

Crash (só em staging/produção, se ligado no build): tipo de erro, mensagem curta, versão do app, sistema (ex. "android 14") e o começo da pilha de chamadas, **sem** ficha, e-mail ou posição. Fica 90 dias no servidor e depois é apagado.

Motivo de não criar conta (só se o piloto escrever e enviar): o texto que ele digita ao dispensar o convite vai pela mesma rota anônima do crash, sem e-mail, sem identificador e sem nada da caderneta. Serve para entender o que falta no app. Responder é opcional, e dispensar o convite funciona igual sem resposta. Fica 90 dias no servidor, como os crashes.

Boas-vindas (uma vez, quando o piloto cria a conta): o e-mail da conta é enviado ao Resend para entregar uma mensagem que explica o que a conta guarda e o que continua só no aparelho. A mensagem não leva nada da caderneta, nem o próprio e-mail no texto. Se o envio falhar, a conta é criada do mesmo jeito.

Os e-mails do app saem de `contato@raulnikroyce.dev`, que aceita resposta. O que o piloto responder é encaminhado pelo Cloudflare para a caixa de e-mail do responsável pelo app, e fica lá. Quem receber a boas-vindas sem ter criado a conta pode responder pedindo, e a conta é apagada.

Recuperação de senha (só quando o piloto pede): o e-mail da conta é enviado ao Resend, provedor de envio de e-mail, para entregar a mensagem com o código de 6 dígitos. O servidor guarda apenas o hash do código, que vale 15 minutos, e apaga o registro na limpeza diária depois de vencido. A mensagem com o código em texto fica no Resend pelo prazo de retenção do serviço e na caixa de e-mail do piloto.

## Permissões no Android

- Internet, conta opcional e mapa OSM
- Localização, último ponto e rota
- Câmera, foto da moto, só neste aparelho
- Notificações, lembretes de óleo e papelada

## Exclusão

No aparelho, apagar o app ou colar um backup vazio. Com conta, no app, Ficha, Conta, **Excluir conta no servidor** (`DELETE /auth/conta`) remove o usuário e os dados remotos (CASCADE), a caderneta na conta inclusive, e revoga as sessões. Para apagar só a caderneta na conta e manter a conta, desligue o interruptor.

Access JWT expira em minutos. Refresh é revogado no sair, na exclusão, na troca de senha (`POST /auth/senha`) e na redefinição por código (`POST /auth/redefinir`). Este aparelho recebe um par novo. Os outros precisam entrar de novo.

## Contato

Titular dos dados, o piloto da conta. Operador da API própria, quem hospeda o `life.and.roads` (porta 3001). Pedidos sobre os seus dados, como ver, corrigir ou apagar, vão para `contato@raulnikroyce.dev`.
