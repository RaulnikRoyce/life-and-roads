import 'package:life_and_roads/features/viagem/data/abastecimento_local_datasource.dart';
import 'package:life_and_roads/features/viagem/data/precos_local_datasource.dart';
import 'package:life_and_roads/features/viagem/domain/precos_litro.dart';
import 'package:life_and_roads/features/viagem/domain/viagem_repository.dart';
import 'package:life_and_roads/viagem/calculo.dart';

class ViagemRepositoryImpl implements ViagemRepository {
  ViagemRepositoryImpl({
    required PrecosLocalDatasource precos,
    required AbastecimentoLocalDatasource abastecimentos,
  })  : _precos = precos,
        _abastecimentos = abastecimentos;

  final PrecosLocalDatasource _precos;
  final AbastecimentoLocalDatasource _abastecimentos;

  @override
  Future<PrecosLitro> lerPrecos() => _precos.ler();

  @override
  Future<void> gravarPrecos(PrecosLitro precos) => _precos.gravar(precos);

  @override
  Future<List<RegistroAbastecimento>> listarAbastecimentos() =>
      _abastecimentos.listar();

  @override
  Future<List<RegistroAbastecimento>> acrescentarAbastecimento(
    RegistroAbastecimento registro,
  ) {
    return _abastecimentos.acrescentar(registro);
  }
}
