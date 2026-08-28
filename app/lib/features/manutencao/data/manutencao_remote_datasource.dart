import 'package:life_and_roads/core/api/openapi/cliente_openapi.dart';
import 'package:life_and_roads/core/api/openapi/dtos.dart';
import 'package:life_and_roads/features/manutencao/data/agenda_manutencao_model.dart';
import 'package:life_and_roads/features/manutencao/domain/agenda_manutencao.dart';

class ManutencaoRemoteDatasource {
  ManutencaoRemoteDatasource({ClienteOpenApi? cliente})
      : _cliente = cliente ?? ClienteOpenApi();

  final ClienteOpenApi _cliente;

  Future<AgendaManutencao?> buscar(String token) async {
    final dto = await _cliente.buscarManutencao(token);
    if (dto == null) return null;
    return AgendaManutencaoModel.fromJson(dto.toJson());
  }

  Future<void> salvar(String token, AgendaManutencao agenda) {
    return _cliente.salvarManutencao(
      token,
      ManutencaoDto.fromJson(AgendaManutencaoModel.toApiJson(agenda)),
    );
  }
}
