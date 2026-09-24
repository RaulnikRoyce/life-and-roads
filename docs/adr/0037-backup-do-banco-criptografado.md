# ADR 0037, backup do banco criptografado

- Status: aceito
- Data: 2026-09-24

## Contexto

O workflow `backup-banco` faz um `mysqldump` semanal do banco de produção e guarda como artifact do GitHub por 90 dias. Foi criado em 21/09/2026 e subia o dump só comprimido, sem criptografia.

Artifact de repositório público pode ser baixado por qualquer pessoa com conta no GitHub. O repositório foi criado em 24/08/2026, e o histórico de eventos desde 28/08 não mostra nenhuma passagem de privado para público, então ele **já era público quando o backup nasceu**. A ADR 0031 dizia que o repositório era privado, e a ADR 0035 que ele tinha virado público depois; as duas estavam erradas nesse ponto. Os dumps ficaram baixáveis desde o primeiro.

Em 24/09 existiam três artifacts de 21/09, de 4,9 KB, 4,9 KB e 1,8 KB, com validade até 20/12. Os dois maiores foram feitos antes da separação dos bancos (ADR 0027) e são do `defaultdb`, com as tabelas do Beco Underground. O Raulnik conferiu o conteúdo: **era tudo dado de teste**, contas fictícias, pedidos de teste e contas de teste do Mercado Pago, sem nenhum cliente real. O dump seguinte estava marcado para 28/09, e esse já pegaria as contas reais do motoclube.

Pela LGPD, quem guarda dado pessoal responde pelas medidas de segurança (art. 46). Um dump aberto e baixável por qualquer um não passa.

## Decisão

**O dump só sai do job criptografado.** AES-256 simétrico com o `gpg`, usando a senha do secret `BACKUP_PASSPHRASE`. O upload pega só o `.sql.gz.gpg`, e o job confere no fim que nenhum arquivo aberto sobrou.

**Sem senha, sem dump.** O primeiro passo exige o secret com pelo menos 20 caracteres, antes de conectar no banco. Se a senha sumir ou for apagada por engano, o job falha em vez de subir o banco aberto.

**O backup prova que restaura.** Antes de apagar o original, o job abre o arquivo cifrado com a mesma senha e compara o hash com o do dump. Se não bater, falha.

**Os três artifacts de 21/09 são apagados à mão** pelo Raulnik, em Actions, no próprio GitHub.

Conferido em 24/09/2026. Os três artifacts antigos foram apagados, e a API do GitHub responde zero backups restantes. A execução #4 do `backup-banco`, já com a criptografia, passou em todos os passos, e o log mostra que só ficaram o `ca.pem`, que é público e não sobe, e o `life-and-roads-20260924.sql.gz.gpg`, com a ida e volta conferida.

## Como restaurar

Com a senha, que fica no gerenciador de senhas do Raulnik e em nenhum outro lugar além do secret:

```
gpg --decrypt life-and-roads-AAAAMMDD.sql.gz.gpg | gunzip | mysql ...
```

O `gpg` pede a senha na hora.

## Consequências

- **Senha perdida é backup perdido.** O GitHub não mostra o valor de um secret depois de salvo, então a única cópia legível é a do gerenciador de senhas.
- Trocar a senha não reabre os backups antigos. Cada arquivo continua pedindo a senha que existia quando ele foi feito, até expirar em 90 dias.
- O artifact continua público, mas sem a senha é um arquivo inútil.
- Os dumps de 21/09 ficaram baixáveis até serem apagados, mas só tinham dado de teste do Beco, sem pessoa real. Não houve titular exposto, então não coube comunicação à ANPD nem aviso a usuários. As senhas estavam em bcrypt com custo 10. Se alguma conta de teste usava um e-mail e uma senha reais do Raulnik, a recomendação é trocar essa senha onde mais ela for usada.
- A lição fica para qualquer workflow novo: o repositório é público, e tudo que um job sobe como artifact é público também.
- Vale a mesma regra para qualquer backup novo, inclusive o backup na nuvem da caderneta que está em planejamento: dado de piloto que sai do banco sai cifrado.
