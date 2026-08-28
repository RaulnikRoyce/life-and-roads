# Especificação, life.and.roads

Documento de requisitos da caderneta digital de **uma motocicleta**. Complementa o [README](../README.md) e a [arquitetura](arquitetura.md).

## 1. Problema

O piloto que viaja ou frequenta motoclube precisa de km do painel, média, tanque, papelada e o último ponto no mapa. Aplicativos de moto no Brasil costumam misturar comunidade, tabela FIPE e marketing. Esta caderneta é local, sem placa e sem frota.

## 2. Objetivos

### 2.1 Geral

Uma caderneta digital para um único veículo, com persistência local e sincronização opcional, cobrindo ficha, manutenção, custo de viagem e último ponto geográfico.

### 2.2 Específicos

1. Registrar marca, modelo, km do painel, tanque e consumo (gasolina e, se flex, álcool).
2. Calcular autonomia (`tanque × km/l`) e custo da rota (`km ÷ km/l × preço`).
3. Registrar consumo no posto com `(km atual − km da ficha) ÷ litros`.
4. Controlar óleo, pneus, revisão, corrente, IPVA, seguro, licenciamento e vencimento da CNH.
5. Exibir o último ponto no mapa e permitir marcas locais de posto ou oficina.
6. Oferecer conta opcional (JWT) apenas para ficha, datas de manutenção e último ponto.

## 3. Requisitos funcionais

| ID | Requisito | Aba |
|---|---|---|
| RF01 | Cadastrar ficha sem placa, chassi ou RENAVAM | Ficha |
| RF02 | Aplicar modelo do catálogo (cidade, estrada, esportiva ou todos) | Ficha |
| RF03 | Foto local da moto (fica neste aparelho) | Ficha |
| RF04 | Backup JSON copiar/colar neste aparelho | Ficha |
| RF05 | Conta opcional (e-mail + senha) | Ficha |
| RF06 | Óleo, pneus e revisão com próxima data derivada da última | Manutenção |
| RF07 | IPVA, seguro e licenciamento com rolagem anual | Manutenção |
| RF08 | CNH com intervalo de 10 ou 5 anos | Manutenção |
| RF09 | Histórico de serviço (tipo, km, reais; máximo 20) | Manutenção |
| RF10 | Estimativa de litros e reais da viagem | Viagem |
| RF11 | Comparar R$/km de gasolina e álcool | Viagem |
| RF12 | Registrar abastecimento e atualizar a média | Viagem |
| RF13 | GPS do último ponto | Mapa |
| RF14 | Pins locais de posto/oficina (toque longo; máximo 30) | Mapa |

## 4. Requisitos não funcionais

| ID | Requisito |
|---|---|
| RNF01 | Interface em português do Brasil |
| RNF02 | Tema claro, escuro e automático |
| RNF03 | Caderneta usável sem rede e sem login |
| RNF04 | Schema da API estrito (`.strict()`). Campo extra é recusado |
| RNF05 | Tempo limite de 8 s nas chamadas HTTP |
| RNF06 | Alvo Android. Sem iOS na v1 |
| RNF07 | API na porta 3001. Senha com bcrypt. JWT |

## 5. Fora de escopo (v1)

Placa, FIPE, preço comunitário de combustível, mecânico com IA, detecção de queda, navegação passo a passo, várias motos, PDF, iOS, envio da foto à API, foto da CNH, extensão do schema remoto para PSI, km de troca, CNH, pins ou backup.
