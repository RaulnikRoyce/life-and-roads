import 'package:life_and_roads/api.dart';

class AuthRemoteDatasource {
  Future<void> registrar(String email, String senha) {
    return ApiCaderneta.registrar(email, senha);
  }

  Future<({String token, String email, String refresh})> login(
    String email,
    String senha,
  ) async {
    final corpo = await ApiCaderneta.login(email, senha);
    final token = '${corpo['token'] ?? ''}';
    final mail = '${corpo['email'] ?? email}';
    final refresh = '${corpo['refreshToken'] ?? ''}';
    if (token.isEmpty) {
      throw FalhaApi('Resposta da API sem token.');
    }
    return (token: token, email: mail, refresh: refresh);
  }

  Future<void> excluirConta(String token) {
    return ApiCaderneta.excluirConta(token);
  }

  Future<({String token, String email, String refresh})> trocarSenha({
    required String token,
    required String senhaAtual,
    required String senhaNova,
  }) async {
    final corpo = await ApiCaderneta.trocarSenha(
      token: token,
      senhaAtual: senhaAtual,
      senhaNova: senhaNova,
    );
    final novoToken = '${corpo['token'] ?? ''}';
    final mail = '${corpo['email'] ?? ''}';
    final refresh = '${corpo['refreshToken'] ?? ''}';
    if (novoToken.isEmpty) {
      throw FalhaApi('Resposta da API sem token.');
    }
    return (token: novoToken, email: mail, refresh: refresh);
  }
}
