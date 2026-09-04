import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mantém credenciais no armazenamento protegido pelo sistema operacional.
class SessaoSegura {
  SessaoSegura({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const chaveToken = 'token_life_and_roads';
  static const chaveRefresh = 'refresh_life_and_roads';

  final FlutterSecureStorage _storage;

  Future<String?> lerToken() => _lerMigrando(chaveToken);

  Future<String?> lerRefresh() => _lerMigrando(chaveRefresh);

  Future<void> gravar({required String token, String? refresh}) async {
    await _storage.write(key: chaveToken, value: token);
    if (refresh != null && refresh.isNotEmpty) {
      await _storage.write(key: chaveRefresh, value: refresh);
    }
    await _removerLegado();
  }

  Future<void> apagar() async {
    await _storage.delete(key: chaveToken);
    await _storage.delete(key: chaveRefresh);
    await _removerLegado();
  }

  Future<String?> _lerMigrando(String chave) async {
    final seguro = await _storage.read(key: chave);
    if (seguro != null && seguro.isNotEmpty) return seguro;

    final prefs = await SharedPreferences.getInstance();
    final legado = prefs.getString(chave);
    if (legado != null && legado.isNotEmpty) {
      await _storage.write(key: chave, value: legado);
      await prefs.remove(chave);
      return legado;
    }
    return null;
  }

  Future<void> _removerLegado() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(chaveToken);
    await prefs.remove(chaveRefresh);
  }
}
