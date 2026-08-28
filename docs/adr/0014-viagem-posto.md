# ADR 0014, Viagem em linguagem de posto

- Status: aceito
- Data: 2026-08-26

## Contexto

Na APK 1.2 o abastecimento falava em fórmula. 32.020 km com 12 L era recusado (média baixa) com a mensagem errada (“km tem que ser maior”). O seletor gasolina/álcool ficava longe do posto. O km da Ficha só gravava no botão Salvar.

## Decisão

- Mensagens de `MontarAbastecimento` distinguem painel, litros e média absurda, **sem** citar km/l.
- Rótulos e subtítulos da Viagem (e km da Ficha) em português de bomba.
- Seletor Gasolina/Álcool também ao lado do abastecimento (`combustivelAbastecimento`).
- Debounce ~800 ms no km da Ficha: grava sozinho se a ficha já existe e o número mudou. Demais campos no Salvar.

Faixa 5–80 e teto 2.000 km no código **não** mudam.

## Consequências

- Recorte intacto. Fases 14–15 (óleo/avisos, catálogo) ficam para o próximo pedido.
