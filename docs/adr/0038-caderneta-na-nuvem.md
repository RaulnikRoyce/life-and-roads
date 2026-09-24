# ADR 0038, caderneta na nuvem

- Status: aceito
- Data: 2026-09-24

## Contexto

Até aqui a conta guardava a ficha sem PSI, as datas de manutenção e o último ponto do GPS. Abastecimentos, serviços, pinos, PSI, km de óleo e corrente, validade da CNH e preços do dia ficavam só no aparelho, e quem trocava de celular perdia justamente o histórico que mais demora para juntar. O backup automático em Download (ADR 0033) ajuda no Android, mas depende de o piloto lembrar de levar o arquivo. E a caderneta do APK e a do app web (ADR 0034) não conversavam.

O Raulnik escolheu quatro coisas, que viraram regra: a chave fica no servidor, para a recuperação de senha continuar devolvendo tudo; o envio é sozinho e sem pressa; a foto fica de fora; e o app pergunta antes de trocar uma caderneta que já existe no aparelho. E pediu um aceite dos termos, porque com a caderneta indo para o servidor o que a pessoa leu passa a importar.

## Decisão

**O que vai para a conta é exatamente o que só existia no aparelho, menos a foto.** Abastecimentos, serviços, pinos, PSI, `ChavesKv.extra` (km de óleo e corrente e CNH) e preços do dia. Ficha, datas e último ponto continuam nas rotas próprias, com o carimbo e o conflito da ADR 0018. Mandar a caderneta inteira criaria duas fontes para a mesma ficha, e restaurar a nuvem num celular novo poderia trocar uma ficha nova por uma velha.

**API.** Módulo `caderneta` com `GET`, `PUT` e `DELETE /caderneta`, todos com token. O conteúdo tem Zod `.strict()` no nível de cima, com oito chaves, e itens livres dentro das listas, para o app ganhar campo novo sem quebrar a API. Corpo até 512 KB só nessa rota; o resto continua em 20 KB. Até 30 envios por conta a cada 15 minutos.

**Cifra.** AES-256-GCM com a chave do env `CADERNETA_CHAVE`, 32 bytes em base64, IV novo a cada gravação e a conta dona como dado autenticado. Um byte mexido no banco faz a abertura falhar, e a cifra de uma conta copiada para a linha de outra não abre. A coluna `versao_chave` deixa trocar a chave um dia sem perder o que já existe. Sem a chave no ambiente, as rotas respondem 503 e o resto da API segue.

**Carimbo e conflito.** O `PUT` leva o carimbo que o aparelho conhece. Se já existe caderneta e o carimbo não bate, responde 409 com o atual e não grava. A checagem roda numa transação com `SELECT ... FOR UPDATE`, e dois envios simultâneos na primeira gravação terminam em um 200 e um 409. O carimbo é `BIGINT` em milissegundos, e não `DATETIME(3)` como o plano previa, porque é o mesmo número do JavaScript e a comparação fica exata.

**Envio pelo app.** `BackupNuvem` espera 2 minutos sem mudança nova, manda na hora quando o app vai para segundo plano e falha em silêncio. Só manda se a assinatura sha256 do pacote mudou. Um aviso único, `CadernetaMudou`, avisa o backup em Download e a nuvem; com ele, pino, serviço novo e preço do dia passaram a entrar também no arquivo em Download, que antes ficava sem eles.

**Decisão ao entrar e ao abrir,** em `DecidirCadernetaNuvem`, sempre depois de a ficha carregar, para o PSI ter onde entrar. Aparelho com dados e conta vazia manda. Aparelho vazio e conta com caderneta traz sem perguntar. Mesmo carimbo manda só se mudou. Mesmo conteúdo sem carimbo só adota. Os dois com histórico diferente perguntam, com o resumo dos dois lados no cartão de conflito.

**Aceite dos termos.** A base legal é a execução do serviço (LGPD, art. 7º, V), e o que forma esse acordo são os Termos de uso. O cadastro tem a caixa "Li e aceito os Termos de uso e a Privacidade", desmarcada, e "Cadastrar" só acende marcada. A versão é a data do texto, hoje `2026-09-24`, e fica em `usuarios.termos_versao` com a hora em `termos_aceitos_em`. Quem já tinha conta vê um cartão no topo da Ficha e nada sobe até responder. O campo é opcional no cadastro enquanto houver APK antigo nos celulares, e nesse caso grava nulo. Login e redefinição de senha devolvem a versão aceita. Mudar o texto é subir a data, e todo mundo aceita de novo.

**Interruptor** "Guardar a caderneta inteira na conta", no bloco Conta, ligado por padrão. Desligar confirma, apaga a cópia da conta e só desliga aqui se o servidor respondeu.

**Criar a conta leva a ficha que já existe no aparelho,** sem esperar o piloto salvar de novo. Antes o app pedia "Agora salve a ficha", e quem não salvava ficava com a caderneta na conta e a ficha fora.

## O que ficou de fora

- A foto, por decisão do Raulnik.
- Cifra de ponta a ponta com a senha do piloto. Seria mais forte, mas a recuperação de senha por e-mail deixaria de devolver a caderneta.
- Interruptor por conta. O interruptor vale por aparelho: desligar no celular A apaga a cópia da conta, e o celular B, se continuar ligado, manda de novo. A confirmação de desligar diz para desligar também no outro. Guardar a escolha no servidor seria mudança de contrato.
- O serviço da Manutenção atualizar o km da ficha. Ficou anotado para depois.

## Consequências

- **A chave vale tanto quanto a senha do backup do banco.** Está no Render e no gerenciador de senhas do Raulnik, e em nenhum outro lugar. Perdida ou trocada sem migração, todas as cadernetas na conta viram arquivo que não abre, e a API responde 500 ao ler. O celular de cada piloto continua com os dados.
- Excluir a conta leva a caderneta junto, pelo `ON DELETE CASCADE`.
- Com conta, o APK e o app web passam a ter a mesma caderneta, que antes eram duas ilhas.
- O cadastro do APK antigo continua funcionando e grava o aceite nulo. Quando esse piloto atualizar, vê o cartão de aceite.
- A conferência de ponta a ponta usa a configuração `api-local` do `.claude/launch.json`, que sobe a API com MySQL local e valores de teste explícitos, sem ler o `.env`.
