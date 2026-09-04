import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/features/auth/data/auth_local_datasource.dart';
import 'package:life_and_roads/features/auth/data/auth_remote_datasource.dart';
import 'package:life_and_roads/features/auth/data/auth_repository_impl.dart';
import 'package:life_and_roads/features/auth/domain/usecases/trocar_senha.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RemotoFake extends AuthRemoteDatasource {
  String? tokenRecebido;
  String? senhaAtual;
  String? senhaNova;
  bool falhar = false;

  @override
  Future<({String token, String email, String refresh})> trocarSenha({
    required String token,
    required String senhaAtual,
    required String senhaNova,
  }) async {
    if (falhar) throw FalhaApi('Senha atual incorreta.');
    tokenRecebido = token;
    this.senhaAtual = senhaAtual;
    this.senhaNova = senhaNova;
    return (token: 'token-novo', email: 'a@b.c', refresh: 'refresh-novo');
  }
}

void main() {
  const regra = TrocarSenha();

  test('senha curta ou igual é recusada na regra', () {
    expect(
      regra.validar(senhaAtual: 'curta', senhaNova: 'senha5678'),
      'Senha de no mínimo 8 caracteres.',
    );
    expect(
      regra.validar(senhaAtual: 'senha1234', senhaNova: 'senha1234'),
      'A senha nova tem que ser diferente da atual.',
    );
    expect(
      regra.validar(senhaAtual: 'senha1234', senhaNova: 'senha5678'),
      isNull,
    );
  });

  test('repositório grava o par novo e mata o refresh antigo', () async {
    SharedPreferences.setMockInitialValues({
      'token_life_and_roads': 'token-velho',
      'refresh_life_and_roads': 'refresh-velho',
      'email_life_and_roads': 'a@b.c',
    });
    final remoto = _RemotoFake();
    final repo = AuthRepositoryImpl(
      local: AuthLocalDatasource(),
      remoto: remoto,
    );

    final sessao = await repo.trocarSenha('senha1234', 'senha5678');
    expect(sessao.token, 'token-novo');
    expect(sessao.email, 'a@b.c');
    expect(remoto.tokenRecebido, 'token-velho');
    expect(remoto.senhaAtual, 'senha1234');
    expect(remoto.senhaNova, 'senha5678');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('token_life_and_roads'), isNull);
    expect(prefs.getString('refresh_life_and_roads'), isNull);
    const storage = FlutterSecureStorage();
    expect(await storage.read(key: 'token_life_and_roads'), 'token-novo');
    expect(await storage.read(key: 'refresh_life_and_roads'), 'refresh-novo');
  });

  test('senha atual errada sobe FalhaApi e não troca o token', () async {
    SharedPreferences.setMockInitialValues({
      'token_life_and_roads': 'token-velho',
      'refresh_life_and_roads': 'refresh-velho',
      'email_life_and_roads': 'a@b.c',
    });
    final remoto = _RemotoFake()..falhar = true;
    final repo = AuthRepositoryImpl(
      local: AuthLocalDatasource(),
      remoto: remoto,
    );

    await expectLater(
      repo.trocarSenha('senha1234', 'senha5678'),
      throwsA(isA<FalhaApi>()),
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('token_life_and_roads'), isNull);
    expect(prefs.getString('refresh_life_and_roads'), 'refresh-velho');
    const storage = FlutterSecureStorage();
    expect(await storage.read(key: 'token_life_and_roads'), 'token-velho');
  });
}
