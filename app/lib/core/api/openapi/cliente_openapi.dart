import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/core/api/openapi/dtos.dart';

/// Cliente HTTP tipado do contrato `docs/openapi.yaml`.
///
/// Transporte (JWT, refresh, timeout) continua em [ApiCaderneta].
class ClienteOpenApi {
  Future<FichaDto?> buscarFicha(String token) async {
    final mapa = await ApiCaderneta.buscarFicha(token);
    if (mapa == null) return null;
    return FichaDto.fromJson(mapa);
  }

  Future<void> salvarFicha(String token, FichaDto ficha) {
    return ApiCaderneta.salvarFicha(token, ficha.toJson());
  }

  Future<ManutencaoDto?> buscarManutencao(String token) async {
    final mapa = await ApiCaderneta.buscarManutencao(token);
    if (mapa == null) return null;
    return ManutencaoDto.fromJson(mapa);
  }

  Future<void> salvarManutencao(String token, ManutencaoDto agenda) {
    return ApiCaderneta.salvarManutencao(token, agenda.toJson());
  }

  Future<LocalizacaoDto?> buscarLocalizacao(String token) async {
    final mapa = await ApiCaderneta.buscarLocalizacao(token);
    if (mapa == null) return null;
    return LocalizacaoDto.fromJson(mapa);
  }

  Future<void> salvarLocalizacao(String token, LocalizacaoDto ponto) {
    return ApiCaderneta.salvarLocalizacao(
      token,
      latitude: ponto.latitude,
      longitude: ponto.longitude,
    );
  }

  Future<Map<String, dynamic>> trocarSenha({
    required String token,
    required String senhaAtual,
    required String senhaNova,
  }) {
    return ApiCaderneta.trocarSenha(
      token: token,
      senhaAtual: senhaAtual,
      senhaNova: senhaNova,
    );
  }
}
