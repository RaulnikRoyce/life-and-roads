import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/core/security/sessao_segura.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('migra tokens legados para o armazenamento seguro', () async {
    SharedPreferences.setMockInitialValues({
      SessaoSegura.chaveToken: 'access-legado',
      SessaoSegura.chaveRefresh: 'refresh-legado',
    });
    const storage = FlutterSecureStorage();
    final sessao = SessaoSegura(storage: storage);

    expect(await sessao.lerToken(), 'access-legado');
    expect(await sessao.lerRefresh(), 'refresh-legado');
    expect(await storage.read(key: SessaoSegura.chaveToken), 'access-legado');
    expect(
      await storage.read(key: SessaoSegura.chaveRefresh),
      'refresh-legado',
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SessaoSegura.chaveToken), isNull);
    expect(prefs.getString(SessaoSegura.chaveRefresh), isNull);
  });

  test('grava e apaga apenas no armazenamento seguro', () async {
    SharedPreferences.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    final sessao = SessaoSegura(storage: storage);

    await sessao.gravar(token: 'access', refresh: 'refresh');
    expect(await storage.read(key: SessaoSegura.chaveToken), 'access');
    expect(await storage.read(key: SessaoSegura.chaveRefresh), 'refresh');

    await sessao.apagar();
    expect(await storage.read(key: SessaoSegura.chaveToken), isNull);
    expect(await storage.read(key: SessaoSegura.chaveRefresh), isNull);
  });
}
