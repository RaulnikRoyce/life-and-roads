# Privacidade, life.and.roads

A caderneta vive **neste aparelho**. A conta é opcional.

## O que o servidor guarda

Com login, e-mail, senha (bcrypt), ficha (sem PSI), datas de manutenção e o último ponto GPS. Refresh token só como hash.

Ficam só no aparelho a foto, o PSI, os pins, os abastecimentos, os serviços, o backup, placa, chassi e RENAVAM.

Crash (só em staging/produção, se ligado no build), tipo de erro e uma mensagem curta, **sem** ficha nem e-mail.

## Permissões no Android

- Internet, conta opcional e mapa OSM
- Localização, último ponto e rota
- Câmera, foto da moto, só neste aparelho
- Notificações, lembretes de óleo e papelada

## Exclusão

No aparelho, apagar o app ou colar um backup vazio. Com conta, no app, Ficha, Conta, **Excluir conta no servidor** (`DELETE /auth/conta`) remove o usuário e os dados remotos (CASCADE) e revoga as sessões.

Access JWT expira em minutos. Refresh é revogado no sair, na exclusão e na troca de senha (`POST /auth/senha`). Este aparelho recebe um par novo. Os outros precisam entrar de novo.

## Contato

Titular dos dados, o piloto da conta. Operador da API própria, quem hospeda o `life.and.roads` (porta 3001).
