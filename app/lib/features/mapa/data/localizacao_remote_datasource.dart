import 'package:latlong2/latlong.dart';
import 'package:life_and_roads/core/api/openapi/cliente_openapi.dart';
import 'package:life_and_roads/core/api/openapi/dtos.dart';

class LocalizacaoRemoteDatasource {
  LocalizacaoRemoteDatasource({ClienteOpenApi? cliente})
      : _cliente = cliente ?? ClienteOpenApi();

  final ClienteOpenApi _cliente;

  Future<LatLng?> buscar(String token) async {
    final dto = await _cliente.buscarLocalizacao(token);
    if (dto == null) return null;
    if (dto.latitude < -90 ||
        dto.latitude > 90 ||
        dto.longitude < -180 ||
        dto.longitude > 180) {
      return null;
    }
    return LatLng(dto.latitude, dto.longitude);
  }

  Future<void> salvar(String token, LatLng ponto) {
    return _cliente.salvarLocalizacao(
      token,
      LocalizacaoDto(latitude: ponto.latitude, longitude: ponto.longitude),
    );
  }
}
