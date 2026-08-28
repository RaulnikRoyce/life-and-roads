import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';

/// Compara só o que a API replica. PSI fica neste aparelho.
class DetectarConflitoFicha {
  bool executar(FichaMoto local, FichaMoto remota) {
    return local.marca != remota.marca ||
        local.modelo != remota.modelo ||
        local.ano != remota.ano ||
        local.cilindrada != remota.cilindrada ||
        local.kmLitro != remota.kmLitro ||
        local.kmLitroAlcool != remota.kmLitroAlcool ||
        local.combustivel != remota.combustivel ||
        local.kmAtual != remota.kmAtual ||
        local.tanqueLitros != remota.tanqueLitros ||
        local.personalizacoes != remota.personalizacoes;
  }
}
