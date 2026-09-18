import 'package:life_and_roads/core/api/openapi/cliente_openapi.dart';
import 'package:life_and_roads/core/api/openapi/dtos.dart';
import 'package:life_and_roads/core/sync/lido_do_servidor.dart';
import 'package:life_and_roads/features/ficha/data/ficha_moto_model.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';

class FichaRemoteDatasource {
  FichaRemoteDatasource({ClienteOpenApi? cliente})
      : _cliente = cliente ?? ClienteOpenApi();

  final ClienteOpenApi _cliente;

  Future<LidoDoServidor<FichaMoto>?> buscar(String token) async {
    final lido = await _cliente.buscarFicha(token);
    if (lido == null) return null;
    return LidoDoServidor(
      FichaMotoModel.fromJson(lido.dado.toJson()),
      atualizadoEm: lido.atualizadoEm,
    );
  }

  /// Carimbo do servidor depois de gravar.
  Future<DateTime?> salvar(String token, FichaMoto ficha) {
    return _cliente.salvarFicha(
      token,
      FichaDto.fromJson(FichaMotoModel.toApiJson(ficha)),
    );
  }
}
