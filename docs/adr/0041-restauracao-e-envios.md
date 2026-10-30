# 0041. Restauração validada e coordenação dos envios

Em 30/10/2026, a auditoria local reproduziu perda de dados em restauração, envio concluído depois de desligar a nuvem, confirmação indevida de envio e importação de medições incompletas. O piloto autorizou corrigir esses pontos e as dependências vulneráveis.

Backups locais são decodificados e validados antes de qualquer escrita. V2 exige ficha e as três listas estruturadas; V1 continua aceitando listas serializadas e campos opcionais do formato antigo. Itens inválidos não são descartados silenciosamente durante restauração. Ficha, foto, listas, preços e metadados de sincronização entram na mesma transação SQLite. Preferências antigas só são removidas após o commit. A restauração da conta também prepara e valida as listas antes de substituir os dados locais.

Medições exigem distâncias e volumes positivos e finitos, método conhecido e marcador coerente. Registros antigos continuam legíveis. Detalhes inválidos em linha já persistida permitem recuperar as colunas do registro como legado, sem derrubar a aba Posto.

O envio da nuvem mantém uma operação aguardável. Desligar suspende novos envios, aguarda o envio atual e só então apaga a cópia remota e os carimbos locais. Falha de exclusão mantém o estado ligado e retoma tentativas. Respostas de uma geração anterior não atualizam o estado depois de pausar ou sair da conta. Ações explícitas aguardam o resultado do envio e só confirmam sucesso depois da confirmação do servidor; conflito ou falha não recebem mensagem de sucesso. Uma verificação de fundo anterior não substitui o resultado de uma ação mais recente na tela.

A troca de combustível marca que há mistura no tanque. Ciclos posteriores continuam fornecendo consumo medido agregado, mas não refinam uma média específica como se o combustível fosse puro. O app não tem medida do combustível restante para afirmar quando a mistura terminou, então mantém essa classificação conservadora; o piloto pode continuar informando as médias da Ficha. O marcador da mistura acompanha os mesmos detalhes JSON do abastecimento, sem nova mudança do esquema SQLite nem do contrato da nuvem.

As dependências npm foram atualizadas dentro das faixas já declaradas, sem atualização forçada. A auditoria deve permanecer sem vulnerabilidades antes de publicar.
