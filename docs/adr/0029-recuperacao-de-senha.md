# ADR 0029, Recuperação de senha

- Status: aceito
- Data: 2026-09-21

## Contexto

Quem esquecia a senha não entrava mais na conta. Trocar a senha (`POST /auth/senha`, ADR 0010) pede a senha atual, e excluir a conta (`DELETE /auth/conta`) pede login. A ficha, as datas e o último ponto guardados no servidor ficavam presos, e o e-mail, que é único em `usuarios`, ficava ocupado por uma conta em que ninguém entrava. O ADR 0010 deixou o e-mail de recuperação de fora de propósito, e o beta fechado com amigos viveu sem isso desde agosto.

## Decisão

Código numérico de 6 dígitos enviado por e-mail e digitado no app, em vez de link. Um link precisaria de uma página web para abrir ou de deep link no app, e o projeto não tem nem um nem outro (`go_router` está fora do recorte). O código vai digitado no app junto com o e-mail e a senha nova.

Duas rotas novas, com contrato em `docs/openapi.yaml` (schemas `RecuperarSenha` e `RedefinirSenha`, sem campo extra):

- `POST /auth/recuperar` `{ email }`. Responde 200 `{ mensagem }` sempre que o e-mail tem formato válido, exista conta ou não, para não entregar quem tem cadastro. Responde 429 quando o e-mail já recebeu 3 códigos na última hora (contando os criados, usados ou não), além do limite por IP que já vale para login e cadastro em `auth.routes.ts`. Responde 503 quando o envio de e-mail não está configurado em produção.
- `POST /auth/redefinir` `{ email, codigo, senhaNova }`. Responde 401 "Código inválido ou vencido." para qualquer falha (e-mail sem conta, código errado, vencido, já usado ou com as tentativas esgotadas), sem dizer qual. No sucesso grava o bcrypt da senha nova, marca o código como usado, revoga todas as sessões da conta (`repo.revogarTodas`) e devolve o mesmo corpo do login (`mensagem`, `token`, `refreshToken`, `expiresIn`, `email`, `id`) pela função `emitir()` que já existe no `auth.service`.

Código e guarda:

- Gerado com `crypto.randomInt(0, 1_000_000)` e zero à esquerda até seis dígitos. Vale 15 minutos e é de uso único. Criar um código novo marca os anteriores da mesma conta como usados, sem apagar, porque a contagem por hora precisa do histórico. Até 5 tentativas erradas por código.
- O servidor guarda só o hash, HMAC-SHA256 com o `JWT_SECRET` (`getJwtSecret()`) sobre o código, comparado com `crypto.timingSafeEqual`. Quem lê o banco não lê o código.
- Tabela `recuperacoes_senha` pela migration `004_recuperacoes_senha.sql` (`usuario_id` com `ON DELETE CASCADE`, `codigo_hash CHAR(64)`, `expira_em`, `tentativas`, `usada_em`, `criado_em`, índices em `usuario_id` e `expira_em`). `schema.sql` não muda, é só o retrato inicial. A limpeza de sessões em `src/server.ts` (`limparSessoes`) também apaga os registros com `expira_em` mais antigo que um dia.

E-mail:

- Módulo `api/src/shared/email/enviar_email.ts`. Com `RESEND_API_KEY` no ambiente, faz `POST https://api.resend.com/emails` com o `fetch` do Node 20, sem SDK. É uma chamada HTTPS só, e uma dependência a menos para acompanhar. Remetente em `EMAIL_REMETENTE`, com `life.and.roads <no-reply@raulnikroyce.dev>` como padrão. Assunto "Seu código para redefinir a senha", texto simples com o código, o aviso de que vale 15 minutos e "se não foi você, ignore".
- Sem a chave, em `NODE_ENV=production` a rota `/auth/recuperar` responde 503 com a mensagem "Recuperação de senha não está ligada neste servidor." Fora de produção o código vai para o logger (`codigo_recuperacao`, com `usuarioId` e `codigo`) e o fluxo segue, o que permite desenvolver e testar sem conta no Resend. `usarTransporte(fn)` deixa os testes trocarem o transporte por uma função que recebe `{ para, assunto, texto }` e capturar o código.
- O envio não é aguardado na resposta de `/auth/recuperar` (promise solta, com `.catch` que registra o erro), então o tempo do envio fica fora da resposta. A contagem por hora e a gravação do código ainda entram nela. Em produção o log não recebe o e-mail do piloto nem o código.
- `RESEND_API_KEY` e `EMAIL_REMETENTE` estão em `api/.env.example`, comentadas como opcionais.

## Consequências

- O endereço de e-mail e o código passam por um terceiro, o Resend, só na hora do envio e só quando o e-mail tem conta. `docs/privacidade.md` e a seção 8 de `docs/arquitetura.md` registram isso.
- Como o envio não é aguardado, uma falha no Resend não chega ao piloto; fica no log do servidor. O piloto pode pedir de novo, dentro do limite de 3 por hora.
- Riscos aceitos. Seis dígitos dão um milhão de combinações; com 5 tentativas por código, 3 códigos por hora por e-mail e o limite por IP, adivinhar o código por tentativa não é viável. Quem tem acesso à caixa de e-mail redefine a senha, como em qualquer recuperação por e-mail. Quem perdeu a senha e o acesso ao e-mail continua sem caminho.
- O 429 por e-mail do contrato só sai quando o e-mail tem conta, porque a contagem por hora é por usuário. Quem pede um quarto código na mesma hora para um e-mail descobre que ele tem cadastro. Risco aceito no beta; o limite por IP de `auth.routes.ts` encarece a varredura em massa.
- Trocar o `JWT_SECRET` invalida os códigos pendentes, porque o hash é calculado com ele. Eles passam a responder "Código inválido ou vencido." e o piloto pede outro.
- Redefinir a senha derruba as sessões de todos os aparelhos. Este recebe um par novo, os outros precisam entrar de novo, como na troca de senha (ADR 0010).
- Registros usados e vencidos ficam na tabela até um dia depois do vencimento e saem na limpeza diária.
- Para ligar em produção, o Raulnik precisa criar a conta no Resend, verificar o domínio `raulnikroyce.dev` com os registros DNS que o painel do Resend mostra, criar a API key e colocar `RESEND_API_KEY` e `EMAIL_REMETENTE` nas variáveis do serviço da API no Render (não são secrets do GitHub). Até lá, `/auth/recuperar` responde 503 em produção.

## Adendo de 22/09/2026, e-mail com a identidade do app

O e-mail passou a ir em HTML junto com o texto puro (`shared/email/modelo_codigo.ts`). O desenho é a tela de abertura do app: fundo asfalto inteiro, a logo grande, a marca em Oswald e o código em 72 px, com o mínimo em volta. A Oswald e a Source Sans 3 vêm do Google Fonts nos clientes que aceitam fonte externa; no Gmail caem em Helvetica e na fonte do sistema. A logo é servida pela própria API em `/marca/logo.png` (`api/public/marca`, cache de um dia, `Cross-Origin-Resource-Policy: cross-origin`, fora do rate limit), com a base em `API_URL_PUBLICA` (padrão `https://api.raulnikroyce.dev`). Sem link clicável, sem pixel de rastreio; o teste garante que a única imagem é a logo da API e a única URL externa é a das fontes. O código é escapado antes de entrar no HTML. Resend ligado em produção em 22/09/2026 com o domínio verificado na região de São Paulo; o e-mail de teste chegou na caixa de entrada.
