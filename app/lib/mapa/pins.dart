import 'package:latlong2/latlong.dart';
import 'package:life_and_roads/core/database/caderneta_banco.dart';
import 'package:life_and_roads/core/database/caderneta_database.dart';

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
    final linhas = await CadernetaBanco.instancia.listarPins();
    return [
      for (final l in linhas)
        PinoMapa(tipo: l.tipo, latitude: l.latitude, longitude: l.longitude),
    ];
  }

  static Future<List<PinoMapa>> salvar(List<PinoMapa> pins) async {
    final lista =
        pins.length <= max ? pins.toList() : pins.sublist(pins.length - max);
    final db = CadernetaBanco.instancia;
    await db.apagarPins();
    for (final p in lista) {
      await db.inserirPin(
        PinsCompanion.insert(
          tipo: p.tipo,
          latitude: p.latitude,
          longitude: p.longitude,
        ),
      );
    }
    return lista;
  }
}
