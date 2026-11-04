import 'package:life_and_roads/features/viagem/domain/precos_litro.dart';
import 'package:life_and_roads/viagem/calculo.dart';

abstract class ViagemRepository {
  Future<void> substituirAbastecimentos(List<RegistroAbastecimento> registros);
  Future<PrecosLitro> lerPrecos();
  Future<void> gravarPrecos(PrecosLitro precos);
  Future<List<RegistroAbastecimento>> listarAbastecimentos();
  Future<List<RegistroAbastecimento>> acrescentarAbastecimento(
    RegistroAbastecimento registro,
  );
}
