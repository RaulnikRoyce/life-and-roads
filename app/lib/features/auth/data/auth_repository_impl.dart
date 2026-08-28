import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/features/auth/data/auth_local_datasource.dart';
import 'package:life_and_roads/features/auth/data/auth_remote_datasource.dart';
import 'package:life_and_roads/features/auth/domain/auth_repository.dart';
import 'package:life_and_roads/features/auth/domain/sessao.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthLocalDatasource local,
    required AuthRemoteDatasource remoto,
  })  : _local = local,
        _remoto = remoto;

  final AuthLocalDatasource _local;
  final AuthRemoteDatasource _remoto;

  @override
  Future<Sessao> carregar() async {
    await ApiCaderneta.carregarBase();
    return Sessao(
      token: await _local.lerToken(),
      email: await _local.lerEmail(),
      servidor: ApiCaderneta.base,
    );
  }

  @override
  Future<Sessao> definirServidor(String url) async {
    await ApiCaderneta.definirBase(url);
    final atual = await carregar();
    return atual.copiarCom(servidor: ApiCaderneta.base);
  }

  @override
  Future<Sessao> registrar(String email, String senha) async {
    await _remoto.registrar(email, senha);
    return entrar(email, senha);
  }

  @override
  Future<Sessao> entrar(String email, String senha) async {
    final login = await _remoto.login(email, senha);
    await _local.gravarSessao(
      login.token,
      login.email,
      refresh: login.refresh,
    );
    return Sessao(
      token: login.token,
      email: login.email,
      servidor: ApiCaderneta.base,
    );
  }

  @override
  Future<Sessao> sair() async {
    await ApiCaderneta.encerrarSessaoRemota();
    await _local.apagarSessao();
    await ApiCaderneta.carregarBase();
    return Sessao(servidor: ApiCaderneta.base);
  }

  @override
  Future<Sessao> excluirConta() async {
    final token = await _local.lerToken();
    if (token != null && token.isNotEmpty) {
      await _remoto.excluirConta(token);
    }
    await _local.apagarSessao();
    await ApiCaderneta.carregarBase();
    return Sessao(servidor: ApiCaderneta.base);
  }

  @override
  Future<Sessao> trocarSenha(String senhaAtual, String senhaNova) async {
    final token = await _local.lerToken();
    if (token == null || token.isEmpty) {
      throw FalhaApi('Entre na conta para trocar a senha.');
    }
    final login = await _remoto.trocarSenha(
      token: token,
      senhaAtual: senhaAtual,
      senhaNova: senhaNova,
    );
    final email = login.email.isEmpty ? (await _local.lerEmail() ?? '') : login.email;
    await _local.gravarSessao(login.token, email, refresh: login.refresh);
    return Sessao(
      token: login.token,
      email: email,
      servidor: ApiCaderneta.base,
    );
  }
}
