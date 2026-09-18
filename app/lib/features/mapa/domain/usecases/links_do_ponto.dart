import 'package:latlong2/latlong.dart';

/// Links a partir de um ponto. Puros, sem plugin, para teste.
///
/// Navegação passo a passo fica fora do app (recorte). Aqui só se entrega
/// o ponto ao app de mapas que o piloto já usa.
class LinksDoPonto {
  const LinksDoPonto();

  String _coord(LatLng p) =>
      '${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}';

  /// `geo:` abre o seletor de apps de mapa no Android (Maps, Waze, etc).
  Uri navegacao(LatLng p, {String? rotulo}) {
    final c = _coord(p);
    final q = rotulo == null || rotulo.trim().isEmpty
        ? c
        : '$c(${Uri.encodeComponent(rotulo.trim())})';
    return Uri.parse('geo:$c?q=$q');
  }

  /// Fallback quando não há app que entenda `geo:` (Chrome, por exemplo).
  Uri navegacaoWeb(LatLng p) =>
      Uri.parse('https://www.google.com/maps/search/?api=1&query=${_coord(p)}');

  /// Texto para o compartilhar do sistema. Só com o toque do piloto.
  String ondeEstou(LatLng p) =>
      'Estou aqui: https://maps.google.com/?q=${_coord(p)}';
}
