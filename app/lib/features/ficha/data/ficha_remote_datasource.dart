import 'package:life_and_roads/core/api/openapi/cliente_openapi.dart';
import 'package:life_and_roads/core/api/openapi/dtos.dart';
import 'package:life_and_roads/features/ficha/data/ficha_moto_model.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';

class FichaRemoteDatasource {
  FichaRemoteDatasource({ClienteOpenApi? cliente})
      : _cliente = cliente ?? ClienteOpenApi();

  final ClienteOpenApi _cliente;

  Future<FichaMoto?> buscar(String token) async {
    final dto = await _cliente.buscarFicha(token);
    if (dto == null) return null;
    return FichaMotoModel.fromJson(dto.toJson());
  }

  Future<void> salvar(String token, FichaMoto ficha) {
    return _cliente.salvarFicha(
      token,
      FichaDto.fromJson(FichaMotoModel.toApiJson(ficha)),
    );
  }
}
