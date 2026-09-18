# ADR 0020, Dados a salvo: backup enviável e dump do banco

- Status: aceito
- Data: 2026-09-18

## Contexto

"Salvar arquivo" gravava o JSON na pasta privada do app, que some ao desinstalar, e "Copiar backup" punha megabytes no clipboard. Nenhum dos dois é um backup de verdade para o piloto. No servidor, o plano grátis da Aiven não faz backup; se o serviço for apagado, a caderneta remota dos pilotos vai junto.

## Decisão

- **App.** "Enviar backup" gera o JSON v2, grava em Documents e abre o compartilhar do sistema (`share_plus`); o piloto escolhe Drive, WhatsApp ou Arquivos. "Restaurar de um arquivo" abre o seletor do sistema (`file_picker`) e restaura. Copiar e Colar continuam como apoio. Nenhuma permissão nova no manifest; os dois plugins usam o seletor do Android.
- O caso de uso `EnviarCadernetaArquivo` recebe a função de enviar por injeção, para os testes não dependerem do plugin. `escolherCadernetaJson` lê por `readAsBytes()` e funciona no Chrome sem `dart:io`.
- **Banco.** Workflow `backup-banco` roda `mysqldump` toda segunda 06:00 UTC contra a Aiven (TLS com a CA), comprime e guarda como artifact por 90 dias. Também roda à mão. Secrets `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `DB_SSL_CA_BASE64` no GitHub. Sanidade: o dump precisa ter pelo menos 5 `CREATE TABLE`.

## Consequências

- O arquivo enviado tem a caderneta inteira, inclusive a foto. Quem tem o arquivo tem a caderneta, como já era com o clipboard; a decisão de para onde mandar é do piloto.
- Artifact do GitHub é backup de emergência, não plano de retenção. Para loja, contratar backup no provedor.
