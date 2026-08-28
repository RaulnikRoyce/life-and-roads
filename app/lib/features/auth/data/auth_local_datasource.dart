import 'package:life_and_roads/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalDatasource {
  static const chaveEmail = 'email_life_and_roads';

  Future<String?> lerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiCaderneta.chaveToken);
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
    await prefs.setString(ApiCaderneta.chaveToken, token);
    await prefs.setString(chaveEmail, email);
    if (refresh != null && refresh.isNotEmpty) {
      await prefs.setString(ApiCaderneta.chaveRefresh, refresh);
    }
  }

  Future<void> apagarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiCaderneta.chaveToken);
    await prefs.remove(ApiCaderneta.chaveRefresh);
    await prefs.remove(chaveEmail);
  }
}
