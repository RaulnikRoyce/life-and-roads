import 'package:life_and_roads/features/auth/domain/sessao.dart';

abstract class AuthRepository {
  Future<Sessao> carregar();
  Future<Sessao> definirServidor(String url);
  /// Cria a conta com o aceite dos termos e entra.
  Future<Sessao> registrar(
    String email,
    String senha, {
    required String termosVersao,
  });

  /// Registra no servidor o aceite de quem já tem conta.
  Future<void> aceitarTermos(String versao);
  Future<Sessao> entrar(String email, String senha);
  Future<Sessao> sair();
  Future<Sessao> excluirConta();
  Future<Sessao> trocarSenha(String senhaAtual, String senhaNova);

  /// Pede o código por e-mail. Não diz se o e-mail tem conta.
  Future<void> recuperarSenha(String email);

  /// Troca a senha com o código e entra neste aparelho, como [entrar].
  Future<Sessao> redefinirSenha(String email, String codigo, String senhaNova);
}
