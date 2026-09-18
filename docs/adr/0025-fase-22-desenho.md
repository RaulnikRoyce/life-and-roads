# ADR 0025, Fase 22: desenho das telas

- Status: aceito
- Data: 2026-09-18

## Contexto

Depois da Fase 21 (movimento curto) e da logo vetorial (ADR 0024), o piloto disse que o app continuava "estático, sem fluidez, faltando um desenho bonito". O diagnóstico: o problema não era só movimento, era hierarquia. Tudo tinha o mesmo peso, o carregamento era uma bolinha, a Ficha era um formulário, a Manutenção uma coluna de datas, e as listas apareciam prontas.

## Decisão

Uma tela por vez, cada uma conferida no navegador antes do commit.

- **Ficha como painel** (`PainelMoto`). Com ficha salva: foto sangrando até as bordas e derretendo no fundo, etiqueta FLEX e nome por cima; km do painel em número grande que conta; consumo, pneu e alcance em pastilhas em cascata. O formulário abre numa folha ("Ajustar números") e salvar fecha a folha. Conflito com o servidor vem antes de tudo, porque pede decisão. Primeira abertura continua com o formulário à vista.
- **Barra inferior** (`BarraAbas`). Pastilha que desliza entre as abas, ícone preenchido na ativa, rótulo mais pesado, retorno tátil no Android. Substitui o `NavigationBar` do Material, cujo indicador só aparece e some.
- **Manutenção como linha do tempo** (`MontarLinhaDoTempo` + `LinhaDoTempo`). Vencimentos do mais urgente ao mais folgado, cada um com a fração do intervalo já passada numa barra (verde, âmbar, vinho). Substitui o cartão de texto dos alertas; o sininho continua com `MontarAvisosCaderneta`.
- **Listas em cascata** (postos, serviços; 40 ms por item, até o oitavo) e **estados vazios** (`EstadoVazio`) com ícone em marca d'água e uma frase que diz o que fazer.
- **Abertura nativa segue o sistema**: `@color/fundo` em `values` e `values-night`, `prefers-color-scheme` no `index.html`. Some o quadro escuro antes do Flutter no tema claro.

Regras mantidas da Fase 21: sem pacote novo, sem loop infinito, movimento entre 180 e 480 ms, nada que atrapalhe leitura no sol ou toque com luva.

## Consequências

- Itens continuam diretos no `ListView` (rolagem preguiçosa e `scrollUntilVisible` dos testes funcionando); a margem lateral é aplicada por item quando o painel sangra.
- Testes de widget que achavam a barra por `NavigationBar` passam a achar por `BarraAbas`; os textos esperados são os mesmos.
- Quatro casos de uso e widgets novos com teste: `MontarLinhaDoTempo` (5 testes), `LogoPintor`, `EntradaSuave` com atraso, `PainelMoto` via os testes de widget existentes.
