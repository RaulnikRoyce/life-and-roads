import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/features/auth/data/auth_local_datasource.dart';
import 'package:life_and_roads/features/auth/data/auth_remote_datasource.dart';
import 'package:life_and_roads/features/auth/data/auth_repository_impl.dart';
import 'package:life_and_roads/features/auth/domain/usecases/redefinir_senha.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RemotoFake extends AuthRemoteDatasource {
  String? emailPedido;
  String? emailRedefinido;
  String? codigo;
  String? senhaNova;
  bool falhar = false;

  @override
  Future<void> recuperarSenha(String email) async {
    if (falhar) throw FalhaApi('Já foram pedidos 3 códigos na última hora.');
    emailPedido = email;
  }

  @override
  Future<ParSessao> redefinirSenha({
    required String email,
    required String codigo,
    required String senhaNova,
  }) async {
    if (falhar) throw FalhaApi('Código inválido ou vencido.');
    emailRedefinido = email;
    this.codigo = codigo;
    this.senhaNova = senhaNova;
    return (
      token: 'token-novo',
      email: email,
      refresh: 'refresh-novo',
      termosVersao: '2026-09-24',
    );
  }
}

AuthRepositoryImpl _repo(_RemotoFake remoto) {
  return AuthRepositoryImpl(local: AuthLocalDatasource(), remoto: remoto);
}

void main() {
  const regra = RedefinirSenha();

  test('e-mail sem @ é recusado no passo 1', () {
    expect(regra.validarEmail(''), 'Informe o e-mail da conta.');
    expect(regra.validarEmail('piloto'), 'Informe o e-mail da conta.');
    expect(regra.validarEmail(' a@b.c '), isNull);
  });

  test('código fora de 6 dígitos e senha fora de 8 a 72 são recusados', () {
    expect(
      regra.validar(email: 'a@b.c', codigo: '12345', senhaNova: 'senha5678'),
      'O código tem 6 dígitos.',
    );
    expect(
      regra.validar(email: 'a@b.c', codigo: '12a456', senhaNova: 'senha5678'),
      'O código tem 6 dígitos.',
    );
    expect(
      regra.validar(email: 'a@b.c', codigo: '123456', senhaNova: 'curta'),
      'Senha de no mínimo 8 caracteres.',
    );
    expect(
      regra.validar(email: 'a@b.c', codigo: '123456', senhaNova: 'x' * 73),
      'Senha de no máximo 72 caracteres.',
    );
    expect(
      regra.validar(email: 'piloto', codigo: '123456', senhaNova: 'senha5678'),
      'Informe o e-mail da conta.',
    );
    expect(
      regra.validar(email: 'a@b.c', codigo: '123456', senhaNova: 'senha5678'),
      isNull,
    );
  });

  test('recuperarSenha repassa o e-mail e não mexe na sessão', () async {
    SharedPreferences.setMockInitialValues({});
    final remoto = _RemotoFake();
    final repo = _repo(remoto);

    await repo.recuperarSenha('a@b.c');
    expect(remoto.emailPedido, 'a@b.c');
    const storage = FlutterSecureStorage();
    expect(await storage.read(key: 'token_life_and_roads'), isNull);
  });

  test('redefinirSenha grava a sessão nova como o login', () async {
    SharedPreferences.setMockInitialValues({});
    final remoto = _RemotoFake();
    final repo = _repo(remoto);

    final sessao = await repo.redefinirSenha('a@b.c', '123456', 'senha5678');
    expect(sessao.token, 'token-novo');
    expect(sessao.email, 'a@b.c');
    expect(sessao.logado, isTrue);
    expect(remoto.emailRedefinido, 'a@b.c');
    expect(remoto.codigo, '123456');
    expect(remoto.senhaNova, 'senha5678');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('email_life_and_roads'), 'a@b.c');
    expect(prefs.getString('token_life_and_roads'), isNull);
    const storage = FlutterSecureStorage();
    expect(await storage.read(key: 'token_life_and_roads'), 'token-novo');
    expect(await storage.read(key: 'refresh_life_and_roads'), 'refresh-novo');
  });

  test(
    'código errado sobe FalhaApi e deixa a sessão local como estava',
    () async {
      SharedPreferences.setMockInitialValues({'email_life_and_roads': 'a@b.c'});
      FlutterSecureStorage.setMockInitialValues({
        'token_life_and_roads': 'token-velho',
        'refresh_life_and_roads': 'refresh-velho',
      });
      final remoto = _RemotoFake()..falhar = true;
      final repo = _repo(remoto);

      await expectLater(
        repo.redefinirSenha('a@b.c', '000000', 'senha5678'),
        throwsA(isA<FalhaApi>()),
      );
      await expectLater(repo.recuperarSenha('a@b.c'), throwsA(isA<FalhaApi>()));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('email_life_and_roads'), 'a@b.c');
      const storage = FlutterSecureStorage();
      expect(await storage.read(key: 'token_life_and_roads'), 'token-velho');
      expect(
        await storage.read(key: 'refresh_life_and_roads'),
        'refresh-velho',
      );
    },
  );
}
