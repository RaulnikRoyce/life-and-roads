# ADR 0022, Mapa: alcance, tema, app de mapas e onde estou

- Status: aceito
- Data: 2026-09-18

## Contexto

O mapa tinha rastreio, último ponto, pins e km de estrada. Faltava responder a pergunta mais comum de quem pega estrada ("até onde eu chego?"), o tile era sempre escuro mesmo no tema claro, e o piloto não tinha como levar um ponto do app para o Maps ou o Waze, nem dizer a alguém onde está.

## Decisão

- **Círculo de alcance.** `AutonomiaNoMapa` calcula tanque × km/l do combustível atual da ficha (`autonomiaKm` já existia). `CircleLayer` com raio em metros em volta da posição. Legenda deixa claro que é linha reta. Sem ficha com tanque, não há círculo.
- **Tile pelo tema.** `CamadaOsm.urlParaTema` escolhe `light_all` ou `dark_all` da CARTO.
- **Abrir no app de mapas.** `LinksDoPonto` (puro) monta `geo:lat,lng?q=lat,lng(rótulo)`; `abrirNoAppDeMapas` tenta o `geo:` e cai para o Google Maps no navegador. Disponível no toque do pino (junto com apagar) e no destino da Viagem. Navegação passo a passo continua fora do recorte: o app entrega o ponto e sai de cena.
- **Onde estou.** Botão ao lado de Rastrear que abre o compartilhar do sistema com um link do último ponto. Só quando o piloto aperta.
- `url_launcher` entra; `share_plus` já estava. Manifest declara `<queries>` para `geo:` e `https:`.

## Consequências

- Tudo local, sem conta e sem API própria. O `geo:` depende de haver um app de mapas; sem ele, abre no navegador.
- O círculo é geodésico aproximado do `flutter_map`; para 300 km de raio a distorção visual é aceitável no Brasil.
