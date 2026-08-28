import 'package:life_and_roads/core/database/armazem_kv.dart';
import 'package:life_and_roads/core/database/chaves_kv.dart';
import 'package:life_and_roads/features/viagem/domain/precos_litro.dart';

class PrecosLocalDatasource {
  static const chaveGasolina = ChavesKv.precoGasolina;
  static const chaveAlcool = ChavesKv.precoAlcool;

  Future<PrecosLitro> ler() async {
    return PrecosLitro(
      gasolina: await ArmazemKv.lerTexto(chaveGasolina) ?? '',
      alcool: await ArmazemKv.lerTexto(chaveAlcool) ?? '',
    );
  }

  Future<void> gravar(PrecosLitro precos) async {
    await ArmazemKv.gravarTexto(chaveGasolina, precos.gasolina.trim());
    await ArmazemKv.gravarTexto(chaveAlcool, precos.alcool.trim());
  }
}
