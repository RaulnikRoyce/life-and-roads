import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Posto ou oficina que o piloto marcou. Sem comunidade, sem placa.
class PinoMapa {
  const PinoMapa({
    required this.tipo,
    required this.latitude,
    required this.longitude,
  });

  /// `posto` ou `oficina`.
  final String tipo;
  final double latitude;
  final double longitude;

  LatLng get ponto => LatLng(latitude, longitude);

  Map<String, dynamic> paraJson() => {
        'tipo': tipo,
        'latitude': latitude,
        'longitude': longitude,
      };

  static PinoMapa? deJson(Object? bruto) {
    if (bruto is! Map) return null;
    final mapa = Map<String, dynamic>.from(bruto);
    final tipo = '${mapa['tipo'] ?? ''}'.trim();
    if (tipo != 'posto' && tipo != 'oficina') return null;
    final lat = (mapa['latitude'] as num?)?.toDouble();
    final lng = (mapa['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return PinoMapa(tipo: tipo, latitude: lat, longitude: lng);
  }
}

class PinsMapa {
  static const chave = 'pins_v1';
  static const max = 30;

  static Future<List<PinoMapa>> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getString(chave);
    if (bruto == null || bruto.isEmpty) return [];
    try {
      final lista = jsonDecode(bruto);
      if (lista is! List) return [];
      return lista.map(PinoMapa.deJson).whereType<PinoMapa>().toList();
    } on FormatException {
      return [];
    }
  }

  static Future<List<PinoMapa>> salvar(List<PinoMapa> pins) async {
    final lista = pins.length <= max ? pins.toList() : pins.sublist(pins.length - max);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      chave,
      jsonEncode([for (final p in lista) p.paraJson()]),
    );
    return lista;
  }
}
