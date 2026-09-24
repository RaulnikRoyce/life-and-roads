import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/backup.dart';
import 'package:life_and_roads/core/backup/backup_nuvem.dart';
import 'package:life_and_roads/core/legal/textos.dart';
import 'package:life_and_roads/features/auth/domain/auth_repository.dart';
import 'package:life_and_roads/features/ficha/domain/resumo_caderneta.dart';
import 'package:life_and_roads/features/ficha/domain/situacao_nuvem.dart';
import 'package:life_and_roads/features/ficha/domain/usecases/decidir_caderneta_nuvem.dart';

typedef BuscarCadernetaNuvem = Future<Map<String, dynamic>?> Function(
  String token,
);
typedef ApagarCadernetaNuvem = Future<void> Function(String token);

/// Caderneta da conta lida da API: o pacote e o carimbo do servidor.
typedef _Lida = ({Map<String, dynamic> conteudo, String carimbo});

/// Orquestra a caderneta na nuvem ao entrar e ao abrir o app (ADR 0038):
/// sessão, aceite, leitura da conta, decisão e o que ela manda fazer.
class CadernetaNuvemRepository {
  CadernetaNuvemRepository({
    required this._backup,
    required this._auth,
    BuscarCadernetaNuvem? buscar,
    ApagarCadernetaNuvem? apagar,
    Future<Map<String, dynamic>> Function()? exportar,
    Future<String?> Function(Map<String, dynamic>)? restaurar,
    this.versaoTermosAtual = versaoTermos,
  }) : _buscar = buscar ?? ApiCaderneta.buscarCaderneta,
       _apagar = apagar ?? ApiCaderneta.apagarCaderneta,
       _exportar = exportar ?? BackupCaderneta.exportarParaNuvem,
       _restaurar = restaurar ?? BackupCaderneta.restaurarDaNuvem;

  final BackupNuvem _backup;
  final AuthRepository _auth;
  final BuscarCadernetaNuvem _buscar;
  final ApagarCadernetaNuvem _apagar;
  final Future<Map<String, dynamic>> Function() _exportar;
  final Future<String?> Function(Map<String, dynamic>) _restaurar;
  final String versaoTermosAtual;
  static const _decidir = DecidirCadernetaNuvem();

  EstadoNuvem get _estado => _backup.estado;

  /// A versão aceita que veio do login ou da redefinição de senha.
  Future<void> registrarAceiteDoLogin(String? versao) =>
      _estado.gravarTermosAceitos(versao);

  /// Decide sem perguntar sempre que der. Falta de rede não muda nada.
  Future<SituacaoNuvem> verificar() async {
    final token = await _token();
    if (token == null) return const SituacaoNuvem();
    if (!await _estado.ligada()) {
      return const SituacaoNuvem(logado: true, ligada: false);
    }
    if (await _estado.termosAceitos() != versaoTermosAtual) {
      return const SituacaoNuvem(logado: true, precisaAceite: true);
    }

    final _Lida? lida;
    try {
      lida = await _ler(token);
    } catch (_) {
      return _situacao(offline: true);
    }

    final local = await _exportar();
    final resumoLocal = ResumoCaderneta.de(local);
    final guardado = await _estado.carimbo();
    final decisao = _decidir.executar(
      aparelho: resumoLocal,
      nuvem: lida == null ? null : ResumoCaderneta.de(lida.conteudo),
      mesmoCarimbo: lida != null && lida.carimbo == guardado,
      mesmoConteudo: lida != null &&
          BackupNuvem.assinar(BackupCaderneta.normalizarNuvem(lida.conteudo)) ==
              BackupNuvem.assinar(local),
    );

    switch (decisao) {
      case DecisaoNuvem.nada:
        await _estado.limparConflito();
      case DecisaoNuvem.enviar:
        if (lida != null && lida.carimbo != guardado) {
          await _estado.adotarCarimbo(lida.carimbo);
        } else {
          await _estado.limparConflito();
        }
        await _backup.enviarAgora();
      case DecisaoNuvem.adotar:
        await _backup.adotarIgual(lida!.carimbo);
      case DecisaoNuvem.restaurar:
        final erro = await _restaurar(lida!.conteudo);
        if (erro != null) return _situacao();
        await _backup.registrarRestaurada(lida.carimbo);
        return _situacao(restaurou: true);
      case DecisaoNuvem.perguntar:
        await _estado.marcarConflito();
        return SituacaoNuvem(
          logado: true,
          conflito: ConflitoCadernetaNuvem(
            aparelho: resumoLocal,
            nuvem: ResumoCaderneta.de(lida!.conteudo),
            nuvemEm: DateTime.tryParse(lida.carimbo),
          ),
          guardadaEm: _data(guardado),
        );
    }
    return _situacao();
  }

  /// Quem já tinha conta aceitou no cartão. Registra no servidor antes de
  /// qualquer coisa subir.
  Future<SituacaoNuvem> aceitar() async {
    await _auth.aceitarTermos(versaoTermosAtual);
    await _estado.gravarTermosAceitos(versaoTermosAtual);
    return verificar();
  }

  /// Desliga e apaga a cópia da conta. Sem a resposta do servidor, nada
  /// muda aqui, para o piloto não achar que apagou o que ficou lá.
  Future<SituacaoNuvem> desligar() async {
    final token = await _token();
    if (token != null) await _apagar(token);
    await _backup.desligar();
    return SituacaoNuvem(logado: token != null, ligada: false);
  }

  Future<SituacaoNuvem> ligar() async {
    await _estado.ligar(true);
    return verificar();
  }

  /// Conflito: fica a deste aparelho, por cima da que está na conta.
  Future<SituacaoNuvem> manterAparelho() async {
    final token = await _token();
    if (token == null) return const SituacaoNuvem();
    final lida = await _ler(token);
    if (lida != null) {
      await _estado.adotarCarimbo(lida.carimbo);
    } else {
      await _estado.limparConflito();
    }
    final resultado = await _backup.enviarAgora();
    // Outro aparelho gravou de novo entre ler e mandar: pergunta outra vez.
    if (resultado == ResultadoNuvem.conflito) return verificar();
    return _situacao();
  }

  /// Conflito: fica a da conta, e a deste aparelho é trocada por ela.
  Future<SituacaoNuvem> usarDaConta() async {
    final token = await _token();
    if (token == null) return const SituacaoNuvem();
    final lida = await _ler(token);
    if (lida == null) {
      await _estado.limparConflito();
      return verificar();
    }
    final erro = await _restaurar(lida.conteudo);
    if (erro != null) throw FalhaApi(erro);
    await _backup.registrarRestaurada(lida.carimbo);
    return _situacao(restaurou: true);
  }

  Future<String?> _token() async {
    final sessao = await _auth.carregar();
    return sessao.logado ? sessao.token : null;
  }

  Future<_Lida?> _ler(String token) async {
    final corpo = await _buscar(token);
    if (corpo == null) return null;
    final conteudo = corpo['conteudo'];
    final carimbo = corpo['atualizadoEm'];
    if (conteudo is! Map || carimbo is! String) {
      throw FalhaApi('Resposta da API sem a caderneta.');
    }
    return (conteudo: Map<String, dynamic>.from(conteudo), carimbo: carimbo);
  }

  Future<SituacaoNuvem> _situacao({
    bool restaurou = false,
    bool offline = false,
  }) async {
    return SituacaoNuvem(
      logado: true,
      guardadaEm: _data(await _estado.carimbo()),
      restaurou: restaurou,
      offline: offline,
    );
  }

  static DateTime? _data(String? carimbo) =>
      carimbo == null ? null : DateTime.tryParse(carimbo)?.toLocal();
}
