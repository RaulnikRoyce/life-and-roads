import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';

/// Camada OSM/CARTO. Sem chave Google. Usada no Mapa e no Destino.
class CamadaOsm extends StatelessWidget {
  const CamadaOsm({super.key, this.attribution = 'OSM · CARTO'});

  final String attribution;

  static const urlEscuro =
      'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
  static const urlClaro =
      'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
  static const userAgent = 'com.raulnik.life_and_roads';

  /// Tile acompanha o tema; antes era sempre o escuro, um retângulo preto
  /// no meio da tela clara.
  static String urlParaTema(Brightness b) =>
      b == Brightness.dark ? urlEscuro : urlClaro;

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: urlParaTema(Theme.of(context).brightness),
      userAgentPackageName: userAgent,
    );
  }
}

class CreditoOsm extends StatelessWidget {
  const CreditoOsm({super.key, this.texto = 'OSM · CARTO'});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return SimpleAttributionWidget(source: Text(texto));
  }
}
