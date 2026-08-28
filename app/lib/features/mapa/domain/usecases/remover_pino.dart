import 'package:life_and_roads/mapa/pins.dart';

class RemoverPino {
  const RemoverPino();

  List<PinoMapa> executar({
    required List<PinoMapa> atuais,
    required PinoMapa alvo,
  }) {
    return [
      for (final p in atuais)
        if (p.tipo != alvo.tipo ||
            p.latitude != alvo.latitude ||
            p.longitude != alvo.longitude)
          p,
    ];
  }
}
