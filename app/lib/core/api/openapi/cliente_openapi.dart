import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/core/api/openapi/dtos.dart';
import 'package:life_and_roads/core/sync/lido_do_servidor.dart';

/// Cliente HTTP tipado do contrato `docs/openapi.yaml`.
///
/// Transporte (JWT, refresh, timeout) continua em [ApiCaderneta].
/// `atualizadoEm` (FichaLida / ManutencaoLida) fica fora do DTO: é só de
/// leitura e o PUT `.strict()` recusa se for junto.
class ClienteOpenApi {
  Future<LidoDoServidor<FichaDto>?> buscarFicha(String token) async {
    final mapa = await ApiCaderneta.buscarFicha(token);
    if (mapa == null) return null;
    return LidoDoServidor(
      FichaDto.fromJson(mapa),
      atualizadoEm: LidoDoServidor.carimbo(mapa['atualizadoEm']),
    );
  }

  /// Devolve o carimbo novo do servidor.
  Future<DateTime?> salvarFicha(String token, FichaDto ficha) async {
    final corpo = await ApiCaderneta.salvarFicha(token, ficha.toJson());
    return LidoDoServidor.carimbo(corpo['atualizadoEm']);
  }

  Future<LidoDoServidor<ManutencaoDto>?> buscarManutencao(String token) async {
    final mapa = await ApiCaderneta.buscarManutencao(token);
    if (mapa == null) return null;
    return LidoDoServidor(
      ManutencaoDto.fromJson(mapa),
      atualizadoEm: LidoDoServidor.carimbo(mapa['atualizadoEm']),
    );
  }

  Future<DateTime?> salvarManutencao(String token, ManutencaoDto agenda) async {
    final corpo = await ApiCaderneta.salvarManutencao(token, agenda.toJson());
    return LidoDoServidor.carimbo(corpo['atualizadoEm']);
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

  Future<void> registrar(CredenciaisDto credenciais) {
    return ApiCaderneta.registrar(credenciais.toJson());
  }

  /// Corpo do login: `token`, `refreshToken`, `email`, `id`.
  Future<Map<String, dynamic>> login(CredenciaisDto credenciais) {
    return ApiCaderneta.login(credenciais.toJson());
  }

  /// Corpo com o par novo (`token`, `refreshToken`, `email`).
  Future<Map<String, dynamic>> trocarSenha(String token, TrocaSenhaDto troca) {
    return ApiCaderneta.trocarSenha(token, troca.toJson());
  }
}
