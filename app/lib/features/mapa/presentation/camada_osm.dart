import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Camada de tiles do OpenStreetMap. Sem chave. Usada no Mapa e no Destino.
///
/// A CARTO passou a exigir chave nos basemaps grátis (tile vinha com
/// "API KEY REQUIRED" estampado). O OSM padrão só tem versão clara; no
/// tema escuro o `darkModeTileBuilder` do flutter_map inverte as cores.
class CamadaOsm extends StatelessWidget {
  const CamadaOsm({super.key});

  static const urlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const userAgent = 'com.raulnik.life_and_roads';

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    return TileLayer(
      urlTemplate: urlTemplate,
      userAgentPackageName: userAgent,
      tileBuilder: escuro ? darkModeTileBuilder : null,
    );
  }
}

/// Atribuição exigida pelo OSM.
class CreditoOsm extends StatelessWidget {
  const CreditoOsm({super.key, this.texto = 'OpenStreetMap'});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return SimpleAttributionWidget(source: Text(texto));
  }
}
