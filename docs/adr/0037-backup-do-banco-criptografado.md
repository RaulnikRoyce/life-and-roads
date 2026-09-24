# ADR 0037, backup do banco criptografado

- Status: aceito
- Data: 2026-09-24

## Contexto

O workflow `backup-banco` faz um `mysqldump` semanal do banco de produção e guarda como artifact do GitHub por 90 dias. Foi criado em 21/09/2026, quando o repositório era privado, e subia o dump só comprimido, sem criptografia.

O repositório virou público depois (ADR 0035), e artifact de repositório público pode ser baixado por qualquer pessoa com conta no GitHub. Em 24/09 existiam três artifacts de 21/09, de 4,9 KB, 4,9 KB e 1,8 KB, com validade até 20/12. Os dois maiores foram feitos antes da separação dos bancos (ADR 0027) e provavelmente são do `defaultdb`, que naquele momento guardava a tabela de usuários do Beco Underground. O dump seguinte estava marcado para 28/09, já com as contas do motoclube.

Pela LGPD, quem guarda dado pessoal responde pelas medidas de segurança (art. 46). Um dump aberto e baixável por qualquer um não passa.

## Decisão

**O dump só sai do job criptografado.** AES-256 simétrico com o `gpg`, usando a senha do secret `BACKUP_PASSPHRASE`. O upload pega só o `.sql.gz.gpg`, e o job confere no fim que nenhum arquivo aberto sobrou.

**Sem senha, sem dump.** O primeiro passo exige o secret com pelo menos 20 caracteres, antes de conectar no banco. Se a senha sumir ou for apagada por engano, o job falha em vez de subir o banco aberto.

**O backup prova que restaura.** Antes de apagar o original, o job abre o arquivo cifrado com a mesma senha e compara o hash com o do dump. Se não bater, falha.

**Os três artifacts de 21/09 são apagados à mão** pelo Raulnik, em Actions, no próprio GitHub.

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
- Se os dumps de 21/09 tinham mesmo os usuários do Beco, esses e-mails e hashes de senha ficaram baixáveis entre o repositório virar público e os artifacts serem apagados. As senhas estão em bcrypt, o que reduz o risco, e o GitHub não mostra quem baixou artifact. Cabe ao Raulnik conferir o conteúdo e decidir se avisa os usuários do Beco.
- Vale a mesma regra para qualquer backup novo, inclusive o backup na nuvem da caderneta que está em planejamento: dado de piloto que sai do banco sai cifrado.
