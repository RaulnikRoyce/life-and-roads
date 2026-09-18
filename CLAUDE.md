# life.and.roads, contexto do projeto

Leia este arquivo inteiro antes de planejar, codar ou responder sobre o repositório. Ele substitui os antigos `Context.md`, `context2`, `context3`, `context4`, `escala.txt` e `cyber.md` do Cursor. O histórico de decisões vive em `docs/adr/`.

## Quem pede

Raulnik (GitHub `RaulnikRoyce`), aluno e piloto. Aula em português do Brasil, com o porquê antes do como, um passo de cada vez e sem despejar arquivo enorme. Explique o que está fazendo enquanto faz.

## Recorte (não muda)

Caderneta de **uma moto**. Flutter (Android) em `app/`, API Node/Express/MySQL em `api/` na porta **3001**. Quatro abas em `IndexedStack` (Ficha, Manutenção, Viagem, Mapa). Offline-first, conta opcional. Mapa com OpenStreetMap.

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

Beta fechado com pilotos, APK `1.2.0+5` instalado e funcionando. `flutter_secure_storage` fica em `^10.3.x` durante o beta (a 11 é breaking e exige passar pela 10 antes). API sem deploy público ainda; `render.yaml` e `docker-compose.yml` prontos.

Auditoria de 17/09/2026 (Claude Code): os cinco itens principais (race no refresh, backup lendo token antigo, JSON malformado em 500, MySQL no CI, data inválida) e os baixos da API (ano congelado, `/auth/sair`, limpeza de sessões, timing do login, `TRUST_PROXY`, fuso do pool) estão corrigidos e testados. O conflito falso de sync em aparelho único foi resolvido com o carimbo `atualizadoEm` (ADR 0018). `ON DUPLICATE KEY UPDATE ... VALUES()` fica como está até confirmar a versão do MySQL da Aiven no log de boot (`"mensagem":"banco"`).

Produção: API no Render (`https://api.raulnikroyce.dev`, blueprint ligado ao `main`, **push = deploy**, migrations rodam no boot), MySQL na Aiven (plano grátis, TLS obrigatório). Plano grátis do Render hiberna após 15 min sem tráfego; a primeira chamada depois disso leva ~20 s e estoura o timeout de 8 s do app.
