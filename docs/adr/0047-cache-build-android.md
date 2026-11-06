# ADR 0047, Cache e preparo do build Android

- Status: aceito
- Data: 2026-11-04

## Decisão

O preparo Android é compartilhado pelo job de APK e por um job de aquecimento em pushes da main. O aquecimento resolve dependências públicas do Gradle, sem compilar APK ou usar keystore. Roda em paralelo aos testes. Isso cria caches na branch padrão, acessíveis às próximas tags; caches isolados em uma tag não seriam reutilizados por outra.

setup-java mantém wrapper e dependências do Gradle, com chave baseada nos arquivos Gradle, wrapper e pubspec.lock. O NDK possui cache separado por sistema, arquitetura e versão. A versão vem do FlutterExtension do SDK selecionado pelo workflow, acompanhando flutter.ndkVersion sem fixar outro NDK no projeto. Não se guarda keystore, key.properties ou SDK inteiro no cache do NDK.

Antes do build, o script confere a revisão declarada e a presença do compilador. Se precisar instalar, usa o sdkmanager já disponível no runner, com até três tentativas e espera de cinco e dez segundos. Cada tentativa limpa somente o pacote incompleto selecionado e o diretório temporário do SDK do job. Um retorno de sucesso sem os arquivos esperados não libera o build.

A primeira execução e mudanças de dependências podem ter cache frio. A redução real de tempo depende do cache e da rede e deve ser medida após publicação. O build e a assinatura do APK continuam condicionados a tags; o app web mantém os gatilhos existentes. Sem alteração das fórmulas ou versões do aplicativo.

## Referências

- https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching#restrictions-for-accessing-a-cache
- https://github.com/actions/setup-java
- https://github.com/actions/cache
- https://developer.android.com/tools/sdkmanager
