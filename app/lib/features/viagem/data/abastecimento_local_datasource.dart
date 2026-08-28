import 'package:life_and_roads/viagem/calculo.dart';
import 'package:life_and_roads/viagem/historico.dart';

class AbastecimentoLocalDatasource {
  Future<List<RegistroAbastecimento>> listar() =>
      HistoricoAbastecimento.carregar();

  Future<List<RegistroAbastecimento>> acrescentar(RegistroAbastecimento r) =>
      HistoricoAbastecimento.acrescentar(r);
}
