import 'package:life_and_roads/core/security/sessao_segura.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalDatasource {
  AuthLocalDatasource({SessaoSegura? sessao})
    : _sessao = sessao ?? SessaoSegura();

  static const chaveEmail = 'email_life_and_roads';
  final SessaoSegura _sessao;

  Future<String?> lerToken() async {
    return _sessao.lerToken();
  }

  Future<String?> lerEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(chaveEmail);
  }

  Future<void> gravarSessao(
    String token,
    String email, {
    String? refresh,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _sessao.gravar(token: token, refresh: refresh);
    await prefs.setString(chaveEmail, email);
  }

  Future<void> apagarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    await _sessao.apagar();
    await prefs.remove(chaveEmail);
  }
}
