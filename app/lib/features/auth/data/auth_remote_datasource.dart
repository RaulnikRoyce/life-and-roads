import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/core/api/openapi/cliente_openapi.dart';
import 'package:life_and_roads/core/api/openapi/dtos.dart';

/// `termosVersao` é a versão dos termos que a conta aceitou, ou null.
typedef ParSessao = ({
  String token,
  String email,
  String refresh,
  String? termosVersao,
});

class AuthRemoteDatasource {
  AuthRemoteDatasource({ClienteOpenApi? cliente})
    : _cliente = cliente ?? ClienteOpenApi();

  final ClienteOpenApi _cliente;

  Future<void> registrar(
    String email,
    String senha, {
    required String termosVersao,
  }) {
    return _cliente.registrar(
      CadastroDto(email: email, senha: senha, termosVersao: termosVersao),
    );
  }

  Future<void> aceitarTermos(String token, String versao) {
    return _cliente.aceitarTermos(token, TermosDto(versao: versao));
  }

  Future<ParSessao> login(String email, String senha) async {
    final corpo = await _cliente.login(
      CredenciaisDto(email: email, senha: senha),
    );
    return _par(corpo, emailPadrao: email);
  }

  Future<void> excluirConta(String token) {
    return ApiCaderneta.excluirConta(token);
  }

  Future<ParSessao> trocarSenha({
    required String token,
    required String senhaAtual,
    required String senhaNova,
  }) async {
    final corpo = await _cliente.trocarSenha(
      token,
      TrocaSenhaDto(senhaAtual: senhaAtual, senhaNova: senhaNova),
    );
    return _par(corpo, emailPadrao: '');
  }

  Future<void> recuperarSenha(String email) {
    return _cliente.recuperarSenha(RecuperarSenhaDto(email: email));
  }

  Future<ParSessao> redefinirSenha({
    required String email,
    required String codigo,
    required String senhaNova,
  }) async {
    final corpo = await _cliente.redefinirSenha(
      RedefinirSenhaDto(email: email, codigo: codigo, senhaNova: senhaNova),
    );
    return _par(corpo, emailPadrao: email);
  }

  /// Login, troca e redefinição de senha devolvem o mesmo par. Sem `token`
  /// é erro.
  ParSessao _par(Map<String, dynamic> corpo, {required String emailPadrao}) {
    final token = '${corpo['token'] ?? ''}';
    if (token.isEmpty) throw FalhaApi('Resposta da API sem token.');
    final termos = corpo['termosVersao'];
    return (
      token: token,
      email: '${corpo['email'] ?? emailPadrao}',
      refresh: '${corpo['refreshToken'] ?? ''}',
      termosVersao: termos is String ? termos : null,
    );
  }
}
