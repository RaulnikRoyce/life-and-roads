import 'package:life_and_roads/core/api/openapi/cliente_openapi.dart';
import 'package:life_and_roads/core/api/openapi/dtos.dart';
import 'package:life_and_roads/core/sync/lido_do_servidor.dart';
import 'package:life_and_roads/features/manutencao/data/agenda_manutencao_model.dart';
import 'package:life_and_roads/features/manutencao/domain/agenda_manutencao.dart';

class ManutencaoRemoteDatasource {
  ManutencaoRemoteDatasource({ClienteOpenApi? cliente})
      : _cliente = cliente ?? ClienteOpenApi();

  final ClienteOpenApi _cliente;

  Future<LidoDoServidor<AgendaManutencao>?> buscar(String token) async {
    final lido = await _cliente.buscarManutencao(token);
    if (lido == null) return null;
    return LidoDoServidor(
      AgendaManutencaoModel.fromJson(lido.dado.toJson()),
      atualizadoEm: lido.atualizadoEm,
    );
  }

  /// Carimbo do servidor depois de gravar.
  Future<DateTime?> salvar(String token, AgendaManutencao agenda) {
    return _cliente.salvarManutencao(
      token,
      ManutencaoDto.fromJson(AgendaManutencaoModel.toApiJson(agenda)),
    );
  }
}
