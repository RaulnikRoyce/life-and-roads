# ADR 0012, Caderneta visível (arquivo e R$/km)

- Status: aceito
- Data: 2026-08-26

## Contexto

O histórico de posto já estava no Drift; o backup ainda era só clipboard. O piloto não via a série de R$/km além da média.

## Decisão

- Backup continua JSON **v2**. Use cases `ExportarCadernetaArquivo` / `ImportarCadernetaArquivo` gravam e leem via `path_provider` (Documents). No Chrome, copiar/colar permanece; salvar arquivo é só no Android.
- UI na Ficha: Copiar, Salvar arquivo, Colar, Restaurar do arquivo. Sem mudar o formato.
- Use case `ResumoConsumo` sobre os últimos 20 postos. Card na Viagem: média + barras (`Column` + `SizedBox`), sem pacote de gráfico. Histórico **não** sobe à API.

## Consequências

- O arquivo fica neste aparelho (`caderneta-life-and-roads.json`). Sem PDF, sem sync de posto.
- Recorte da v1 intacto: uma moto, quatro abas, OSM, API opcional.
