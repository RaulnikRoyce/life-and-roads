import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_and_roads/core/backup/backup_automatico.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/core/sync/ficha_sync_store.dart';
import 'package:life_and_roads/features/auth/data/auth_local_datasource.dart';
import 'package:life_and_roads/features/auth/data/auth_remote_datasource.dart';
import 'package:life_and_roads/features/auth/data/auth_repository_impl.dart';
import 'package:life_and_roads/features/auth/domain/auth_repository.dart';
import 'package:life_and_roads/features/auth/domain/usecases/redefinir_senha.dart';
import 'package:life_and_roads/features/auth/domain/usecases/trocar_senha.dart';
import 'package:life_and_roads/features/ficha/data/ficha_local_datasource.dart';
import 'package:life_and_roads/features/ficha/data/ficha_remote_datasource.dart';
import 'package:life_and_roads/features/ficha/data/ficha_repository_impl.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_moto.dart';
import 'package:life_and_roads/features/ficha/domain/ficha_repository.dart';
import 'package:life_and_roads/features/ficha/presentation/ficha_estado.dart';

final authLocalDatasourceProvider = Provider<AuthLocalDatasource>(
  (_) => AuthLocalDatasource(),
);

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>(
  (_) => AuthRemoteDatasource(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    local: ref.watch(authLocalDatasourceProvider),
    remoto: ref.watch(authRemoteDatasourceProvider),
  ),
);

final fichaLocalDatasourceProvider = Provider<FichaLocalDatasource>(
  (_) => FichaLocalDatasource(),
);

final fichaRemoteDatasourceProvider = Provider<FichaRemoteDatasource>(
  (_) => FichaRemoteDatasource(),
);

final fichaSyncStoreProvider = Provider<FichaSyncStore>(
  (_) => FichaSyncStore(),
);

final fichaRepositoryProvider = Provider<FichaRepository>(
  (ref) => FichaRepositoryImpl(
    local: ref.watch(fichaLocalDatasourceProvider),
    remoto: ref.watch(fichaRemoteDatasourceProvider),
    auth: ref.watch(authRepositoryProvider),
    sync: ref.watch(fichaSyncStoreProvider),
  ),
);

class FichaController extends Notifier<FichaEstado> {
  AuthRepository get _auth => ref.read(authRepositoryProvider);
  FichaRepository get _ficha => ref.read(fichaRepositoryProvider);
  static const _trocarSenha = TrocarSenha();
  static const _redefinirSenha = RedefinirSenha();

  @override
  FichaEstado build() => const FichaEstado();

  /// Sobe a cada salvar(). Um carregar() antigo que termine depois de um
  /// salvar() não pode sobrescrever o que o piloto acabou de gravar.
  int _geracao = 0;

  /// Aparelho primeiro (tela abre na hora), servidor por trás. Com a API
  /// hibernada no Render, a primeira resposta pode levar ~20 s; o piloto
  /// não fica esperando por isso.
  Future<void> carregar() async {
    state = state.copiarCom(
      carregando: state.ficha == null,
      limparErro: true,
      limparAviso: true,
    );
    final geracao = _geracao;
    final local = await _ficha.carregarLocal();
    state = FichaEstado(
      carregando: false,
      sincronizando: local.sessao.logado,
      ficha: local.ficha,
      remoto: local.remoto,
      token: local.sessao.token,
      email: local.sessao.email,
      servidor: local.sessao.servidor,
      sync: local.sync,
    );
    if (!local.sessao.logado) return;

    final carregada = await _ficha.carregar();
    if (geracao != _geracao) {
      state = state.copiarCom(sincronizando: false);
      return;
    }
    state = FichaEstado(
      carregando: false,
      ficha: carregada.ficha,
      remoto: carregada.remoto,
      token: carregada.sessao.token,
      email: carregada.sessao.email,
      servidor: carregada.sessao.servidor,
      offline: carregada.offline,
      sync: carregada.sync,
    );
  }

  Future<void> salvar(FichaMoto ficha, {bool silencioso = false}) async {
    _geracao++;
    final resultado = await _ficha.salvar(ficha);
    ref.read(backupAutomaticoProvider).agendar();
    state = state.copiarCom(
      ficha: resultado.ficha,
      aviso: silencioso ? null : resultado.mensagem,
      limparAviso: silencioso,
      offline: resultado.offline,
      sync: resultado.sync,
      limparErro: true,
    );
  }

  Future<void> cadastrar({
    required String email,
    required String senha,
    required String servidor,
  }) async {
    if (email.isEmpty || senha.length < 8) {
      state = state.copiarCom(
        erro: 'E-mail e senha de no mínimo 8 caracteres.',
        limparAviso: true,
      );
      return;
    }
    await _auth.definirServidor(servidor);
    try {
      final sessao = await _auth.registrar(email, senha);
      state = state.copiarCom(
        token: sessao.token,
        email: sessao.email,
        servidor: sessao.servidor,
        aviso: 'Conta criada. Agora salve a ficha para ela ir ao servidor.',
        limparErro: true,
        offline: false,
      );
    } on FalhaApi catch (e) {
      state = state.copiarCom(erro: e.mensagem, limparAviso: true);
    } catch (_) {
      state = state.copiarCom(
        erro: 'API fora do ar. No celular, use o IP do PC na porta 3001.',
        offline: true,
        limparAviso: true,
      );
    }
  }

  Future<void> entrar({
    required String email,
    required String senha,
    required String servidor,
  }) async {
    if (email.isEmpty || senha.isEmpty) {
      state = state.copiarCom(
        erro: 'Informe e-mail e senha.',
        limparAviso: true,
      );
      return;
    }
    await _auth.definirServidor(servidor);
    try {
      final sessao = await _auth.entrar(email, senha);
      final carregada = await _ficha.carregar();
      state = FichaEstado(
        carregando: false,
        ficha: carregada.ficha,
        remoto: carregada.remoto,
        token: sessao.token,
        email: sessao.email,
        servidor: sessao.servidor,
        aviso: carregada.sync.emConflito
            ? 'A ficha do servidor é diferente desta. Escolha o que fica.'
            : 'Entrou. A ficha do servidor, se existir, já veio.',
        offline: carregada.offline,
        sync: carregada.sync,
      );
    } on FalhaApi catch (e) {
      state = state.copiarCom(erro: e.mensagem, limparAviso: true);
    } catch (_) {
      state = state.copiarCom(
        erro: 'API fora do ar. No celular, use o IP do PC na porta 3001.',
        offline: true,
        limparAviso: true,
      );
    }
  }

  Future<void> sair() async {
    final sessao = await _auth.sair();
    state = state.copiarCom(
      limparSessao: true,
      limparRemoto: true,
      servidor: sessao.servidor,
      limparAviso: true,
      limparErro: true,
      offline: false,
    );
  }

  Future<void> excluirConta() async {
    try {
      final sessao = await _auth.excluirConta();
      state = state.copiarCom(
        limparSessao: true,
        servidor: sessao.servidor,
        aviso: 'Conta apagada no servidor. A caderneta neste aparelho ficou.',
        limparErro: true,
        offline: false,
      );
    } on FalhaApi catch (e) {
      state = state.copiarCom(erro: e.mensagem, limparAviso: true);
    } catch (_) {
      state = state.copiarCom(
        erro: 'API fora do ar. A conta não foi apagada no servidor.',
        offline: true,
        limparAviso: true,
      );
    }
  }

  Future<void> trocarSenha({
    required String senhaAtual,
    required String senhaNova,
  }) async {
    final erro = _trocarSenha.validar(
      senhaAtual: senhaAtual,
      senhaNova: senhaNova,
    );
    if (erro != null) {
      state = state.copiarCom(erro: erro, limparAviso: true);
      return;
    }
    try {
      final sessao = await _auth.trocarSenha(senhaAtual, senhaNova);
      state = state.copiarCom(
        token: sessao.token,
        email: sessao.email,
        servidor: sessao.servidor,
        aviso: 'Senha alterada. Os outros aparelhos precisam entrar de novo.',
        limparErro: true,
        offline: false,
      );
    } on FalhaApi catch (e) {
      state = state.copiarCom(erro: e.mensagem, limparAviso: true);
    } catch (_) {
      state = state.copiarCom(
        erro: 'API fora do ar. A senha não foi alterada.',
        offline: true,
        limparAviso: true,
      );
    }
  }

  /// Passo 1 da recuperação: pede o código por e-mail. Sem aviso de sucesso
  /// no estado porque a folha aberta cobre o snackbar; ela mesma diz que o
  /// código foi. `erro == null` depois do await significa que foi.
  /// Recebe o servidor do campo, como [entrar], para o pedido não ir à base
  /// carregada no boot quando o piloto ainda não entrou.
  Future<void> recuperarSenha({
    required String email,
    required String servidor,
  }) async {
    state = state.copiarCom(limparErro: true, limparAviso: true);
    final erro = _redefinirSenha.validarEmail(email);
    if (erro != null) {
      state = state.copiarCom(erro: erro);
      return;
    }
    await _auth.definirServidor(servidor);
    try {
      await _auth.recuperarSenha(email);
      state = state.copiarCom(offline: false);
    } on FalhaApi catch (e) {
      state = state.copiarCom(erro: e.mensagem);
    } catch (_) {
      state = state.copiarCom(
        erro: 'API fora do ar. O código não foi enviado.',
        offline: true,
      );
    }
  }

  /// Passo 2: senha nova com o código. No sucesso a API entrega um par novo
  /// e o estado fica logado como depois de [entrar], com a ficha do servidor.
  Future<void> redefinirSenha({
    required String email,
    required String codigo,
    required String senhaNova,
    required String servidor,
  }) async {
    state = state.copiarCom(limparErro: true, limparAviso: true);
    final erro = _redefinirSenha.validar(
      email: email,
      codigo: codigo,
      senhaNova: senhaNova,
    );
    if (erro != null) {
      state = state.copiarCom(erro: erro);
      return;
    }
    await _auth.definirServidor(servidor);
    try {
      final sessao = await _auth.redefinirSenha(email, codigo, senhaNova);
      final carregada = await _ficha.carregar();
      state = FichaEstado(
        carregando: false,
        ficha: carregada.ficha,
        remoto: carregada.remoto,
        token: sessao.token,
        email: sessao.email,
        servidor: sessao.servidor,
        aviso: carregada.sync.emConflito
            ? 'A ficha do servidor é diferente desta. Escolha o que fica.'
            : 'Senha redefinida. Os outros aparelhos precisam entrar de novo.',
        offline: carregada.offline,
        sync: carregada.sync,
      );
    } on FalhaApi catch (e) {
      state = state.copiarCom(erro: e.mensagem);
    } catch (_) {
      state = state.copiarCom(
        erro: 'API fora do ar. A senha não foi alterada.',
        offline: true,
      );
    }
  }

  Future<void> manterLocal() async {
    final r = await _ficha.manterLocal();
    state = state.copiarCom(
      ficha: r.ficha,
      limparRemoto: true,
      offline: r.offline,
      sync: r.sync,
      aviso: r.offline
          ? 'Ficou neste aparelho. Reenvia quando a API voltar.'
          : 'Esta ficha foi para o servidor.',
      limparErro: true,
    );
  }

  Future<void> usarRemoto() async {
    final r = await _ficha.usarRemoto();
    state = FichaEstado(
      carregando: false,
      ficha: r.ficha,
      token: r.sessao.token,
      email: r.sessao.email,
      servidor: r.sessao.servidor,
      offline: r.offline,
      sync: r.sync,
      aviso: 'Ficha do servidor neste aparelho. PSI local ficou.',
    );
  }
}

final fichaControllerProvider = NotifierProvider<FichaController, FichaEstado>(
  FichaController.new,
);
