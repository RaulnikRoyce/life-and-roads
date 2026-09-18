import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/viagem/calculo.dart';

/// Raio do círculo de alcance: tanque cheio × km/l do combustível atual.
///
/// É linha reta, não estrada. Serve para "até onde eu chego", não para
/// planejar parada. Null quando a ficha não tem tanque ou consumo.
class AutonomiaNoMapa {
  const AutonomiaNoMapa();

  double? executar(FichaMoto? ficha) {
    if (ficha == null) return null;
    final tanque = ficha.tanqueLitros;
    if (tanque == null) return null;
    final kmPorLitro = ficha.combustivel == Combustivel.alcool
        ? (ficha.kmLitroAlcool ?? ficha.kmLitro)
        : ficha.kmLitro;
    return autonomiaKm(tanqueLitros: tanque, kmPorLitro: kmPorLitro);
  }
}
