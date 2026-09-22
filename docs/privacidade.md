# Privacidade, life.and.roads

A caderneta vive **neste aparelho**. A conta é opcional.

## O que o servidor guarda

Com login, e-mail, senha (bcrypt), ficha (sem PSI), datas de manutenção e o último ponto GPS. Refresh token só como hash.

Ficam só no aparelho a foto, o PSI, os pins, os abastecimentos, os serviços, o backup, placa, chassi e RENAVAM.

Backup automático, **só no app de Android**: a cada mudança na caderneta o app grava uma cópia em `Download/life.and.roads/caderneta.json`, no próprio aparelho. Esse arquivo fica visível no gerenciador de arquivos e sobrevive a desinstalar o app, de propósito, para o piloto não perder a caderneta ao trocar de celular. Nada é enviado; quem decide compartilhar é o piloto, pelo botão Enviar backup.

No app web instalado na tela inicial não existe essa cópia automática, porque o navegador não escreve em pasta do aparelho sem o piloto confirmar. Ali a caderneta fica guardada dentro do próprio navegador e sai só pelo botão Enviar backup. Vale saber que apagar os dados do site, ou o app da tela inicial, apaga a caderneta junto.

Crash (só em staging/produção, se ligado no build): tipo de erro, mensagem curta, versão do app, sistema (ex. "android 14") e o começo da pilha de chamadas, **sem** ficha, e-mail ou posição. Fica 90 dias no servidor e depois é apagado.

Motivo de não criar conta (só se o piloto escrever e enviar): o texto que ele digita ao dispensar o convite vai pela mesma rota anônima do crash, sem e-mail, sem identificador e sem nada da caderneta. Serve para entender o que falta no app. Responder é opcional, e dispensar o convite funciona igual sem resposta. Fica 90 dias no servidor, como os crashes.

Recuperação de senha (só quando o piloto pede): o e-mail da conta é enviado ao Resend, provedor de envio de e-mail, para entregar a mensagem com o código de 6 dígitos. O servidor guarda apenas o hash do código, que vale 15 minutos, e apaga o registro na limpeza diária depois de vencido. A mensagem com o código em texto fica no Resend pelo prazo de retenção do serviço e na caixa de e-mail do piloto.

## Permissões no Android

- Internet, conta opcional e mapa OSM
- Localização, último ponto e rota
- Câmera, foto da moto, só neste aparelho
- Notificações, lembretes de óleo e papelada

## Exclusão

No aparelho, apagar o app ou colar um backup vazio. Com conta, no app, Ficha, Conta, **Excluir conta no servidor** (`DELETE /auth/conta`) remove o usuário e os dados remotos (CASCADE) e revoga as sessões.

Access JWT expira em minutos. Refresh é revogado no sair, na exclusão, na troca de senha (`POST /auth/senha`) e na redefinição por código (`POST /auth/redefinir`). Este aparelho recebe um par novo. Os outros precisam entrar de novo.

## Contato

Titular dos dados, o piloto da conta. Operador da API própria, quem hospeda o `life.and.roads` (porta 3001).
