# ADR 0046, Aviso de atualização do APK

- Status: aceito
- Data: 2026-11-04

## Decisão

O Android verifica a última Release estável pública do repositório oficial ao abrir as abas, uma vez por sessão e sem bloquear a abertura. A Ficha oferece consulta manual e mostra um aviso no topo quando existe APK de versão superior. Web e outras plataformas não consultam esse serviço nem mostram o aviso Android.

A versão instalada vem de package_info_plus, incluindo o build real do APK. APP_VERSION continua destinado ao diagnóstico. A comparação usa componentes numéricos da versão; uma versão igual ou anterior não é oferecida. O build não é usado para detectar substituições de arquivo na mesma tag. Uma versão estável pode substituir uma prévia instalada com os mesmos componentes.

Somente o arquivo life-and-roads-beta-aberto.apk publicado na mesma tag, por HTTPS e no caminho do repositório oficial, libera o botão. Rascunhos, prévias e tags desconhecidas são recusados. Uma Release mais nova sem arquivo pronto é indicada como em preparação. O download usa o link específico da tag consultada para entregar a versão anunciada.

A consulta tem cliente HTTP próprio, prazo de oito segundos e não envia dados da caderneta nem credenciais da conta do app. Falhas automáticas são silenciosas; a consulta manual informa indisponibilidade e permite tentar novamente. Consultas simultâneas e abertura duplicada são bloqueadas, e respostas após descarte são ignoradas. Não há polling, armazenamento de preferências ou mudança de API.

O botão abre o download externamente, e o piloto confirma a instalação no Android. Abrir o link não marca o app como atualizado. package_info_plus 10.2.1 já existia como dependência transitiva e passa a ser declarado diretamente, sem alteração de versão.
