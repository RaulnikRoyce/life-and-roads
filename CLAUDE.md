# life.and.roads, contexto do projeto

Leia este arquivo inteiro antes de planejar, codar ou responder sobre o repositório. Ele substitui os antigos `Context.md`, `context2`, `context3`, `context4`, `escala.txt` e `cyber.md` do Cursor. O histórico de decisões vive em `docs/adr/`.

## Quem pede

Raulnik (GitHub `RaulnikRoyce`), aluno e piloto. Aula em português do Brasil, com o porquê antes do como, um passo de cada vez e sem despejar arquivo enorme. Explique o que está fazendo enquanto faz.

## Recorte (não muda)

Caderneta de **uma moto**. Flutter (Android) em `app/`, API Node/Express/MySQL em `api/` na porta **3001**. Quatro abas em `IndexedStack` (Ficha, Manutenção, Posto, Viagem; a pasta do Posto continua `features/viagem`, a da Viagem é `features/mapa`, ADR 0030). Offline-first, conta opcional. Mapa com OpenStreetMap.

Fora do recorte: iOS, segunda moto, frota, placa, chassi, RENAVAM, FIPE, rede social, PDF de oficina, upload de foto, microsserviços, `go_router`.

Contratos que não se estendem sem pedido explícito. Zod `.strict()` da ficha, manutenção e localização. PSI, km de óleo/corrente, CNH, pins, foto, histórico e backup ficam **só no aparelho**.

Prefs (`SharedPreferences`) guardam só e-mail, tema e `api_base_v1`. Token e refresh ficam no `flutter_secure_storage` (`SessaoSegura`). Todo o resto está no Drift (`CadernetaDatabase`).

## Estrutura

`app/lib/features/<ficha|manutencao|viagem|mapa|auth>/{data,domain,presentation}`. Regra nova entra em `domain/usecases/`; repositório só orquestra datasources; tela só observa o controller Riverpod. `app/lib/core/` para config, banco, sync, segurança e monitor.

`api/src/modules/<auth|ficha|manutencao|localizacao|monitor>/` com `routes → controller → service → repository`. `api/src/shared/` para config, database, http e erros. Migrations em `api/database/migrations/`, aplicadas no boot.

## Processo

- Sem `git commit`, `git push` ou build de APK a menos que seja pedido.
- Um pedido, uma mudança. Alterar, testar, entregar. Sem agentes paralelos.
- Antes de entregar: `flutter analyze --no-fatal-infos` e `flutter test` em `app/`; `npm run typecheck` e `npm test` em `api/`. Se a ferramenta não existir na máquina, dizer isso na entrega em vez de fingir que rodou.
- Mudança de arquitetura ou de contrato gera ADR em `docs/adr/00NN-nome.md` e atualiza `docs/openapi.yaml` quando a API muda.
- `pubspec.yaml` só sobe de versão em fase de release.
- Segurança. Diagnóstico primeiro (o que existe, o que falta, risco no recorte atual versus risco em VPS), correção só como patch pontual pedido. Nada ofensivo (scanner, exploit, brute-force, engenharia reversa do APK).

## Copy visível (app, README, docs)

Português comum, sem gíria de posto e sem fórmula na tela (`÷`, `×`, `km/l`, `R$/km` como explicação, "painel − ficha"). Número no card pode. Sem travessão, sem dois-pontos anunciando conclusão, sem "não é X, é Y", sem sequência de frases curtas para dar ritmo, sem ênclise. Sem metáfora, slogan ou jargão ("ponta a ponta", "AI-First"). Comece pela informação, corte adjetivo que não descreve nada.

## Estado (set/2026)

Beta fechado com pilotos. Release `1.2.1+6` (tag `v1.2.1`, 18/09/2026) com todas as correções e a Fase 22; o APK `1.2.0+5` anterior ainda pode estar em alguns aparelhos. `flutter_secure_storage` fica em `^10.3.x` durante o beta (a 11 é breaking e exige passar pela 10 antes). 

Auditoria de 17/09/2026 (Claude Code): os cinco itens principais (race no refresh, backup lendo token antigo, JSON malformado em 500, MySQL no CI, data inválida) e os baixos da API (ano congelado, `/auth/sair`, limpeza de sessões, timing do login, `TRUST_PROXY`, fuso do pool) estão corrigidos e testados. O conflito falso de sync em aparelho único foi resolvido com o carimbo `atualizadoEm` (ADR 0018). Upserts usam a sintaxe `VALUES (...) AS novo ON DUPLICATE KEY UPDATE col = novo.col` (MySQL ≥ 8.0.20; produção é 8.4.8 na Aiven, compose e CI usam `mysql:8.0`). Não usar `VALUES(col)`, que está obsoleto.

Produção: API no Render (`https://api.raulnikroyce.dev`, blueprint ligado ao `main`, **push = deploy**, migrations rodam no boot), MySQL na Aiven (plano grátis, TLS obrigatório, banco `life_and_roads`; o serviço é dividido com o Beco Underground, que usa o `defaultdb`, e os dois nunca mais apontam para o mesmo banco, ADR 0027). Plano grátis do Render hiberna após 15 min sem tráfego; a primeira chamada depois disso leva ~20 s. O app mostra o aparelho primeiro e sincroniza por trás, com `aquecer()` na abertura e timeout de 25 s até a primeira resposta (ADR 0019). Um monitor do UptimeRobot (conta do Raulnik) bate em `/ready` a cada 5 min desde 18/09/2026, o que mantém Render e Aiven acordados e avisa por e-mail se caírem. Backup semanal do banco funcionando desde 21/09/2026 (workflow `backup-banco`, artifact de 90 dias). Até 21/09 nenhum piloto tinha criado conta ou sincronizado; todos usam o app só no aparelho. Primeira abertura em três passos (ADR 0028) e recuperação de senha por código no e-mail (ADR 0029) entraram em 21/09/2026; a recuperação responde 503 em produção até `RESEND_API_KEY` e `EMAIL_REMETENTE` entrarem no Render (conta no Resend com o domínio `raulnikroyce.dev` verificado). Redesenho das abas como painéis em 21/09/2026: Manutenção (anel de saúde, cartões por grupo com folha), Posto e Viagem (ADR 0030).
