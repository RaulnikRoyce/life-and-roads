import 'package:life_and_roads/features/auth/domain/sessao.dart';

abstract class AuthRepository {
  Future<Sessao> carregar();
  Future<Sessao> definirServidor(String url);
  Future<Sessao> registrar(String email, String senha);
  Future<Sessao> entrar(String email, String senha);
  Future<Sessao> sair();
  Future<Sessao> excluirConta();
  Future<Sessao> trocarSenha(String senhaAtual, String senhaNova);
}
