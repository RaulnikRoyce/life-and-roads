import 'package:life_and_roads/mapa/pins.dart';

/// Acrescenta posto ou oficina, no máximo 30, só neste aparelho.
class AcrescentarPino {
  const AcrescentarPino();

  List<PinoMapa>? executar({
    required List<PinoMapa> atuais,
    required String tipo,
    required double latitude,
    required double longitude,
  }) {
    final pino = PinoMapa.deJson({
      'tipo': tipo,
      'latitude': latitude,
      'longitude': longitude,
    });
    if (pino == null) return null;
    return [...atuais, pino];
  }
}
