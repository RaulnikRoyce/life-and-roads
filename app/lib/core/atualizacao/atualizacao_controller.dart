import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_and_roads/core/atualizacao/servico_atualizacao.dart';
import 'package:life_and_roads/core/atualizacao/versao_app.dart';

final atualizacaoSuportadaProvider = Provider<bool>(
  (_) => !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
);
final fonteAtualizacaoProvider = Provider<FonteAtualizacao>(
  (_) => ServicoAtualizacao(),
);

enum SituacaoAtualizacao {
  inicial,
  atualizado,
  disponivel,
  preparando,
  indisponivel,
}

class EstadoAtualizacao {
  const EstadoAtualizacao({
    this.instalada,
    this.publicada,
    this.situacao = SituacaoAtualizacao.inicial,
    this.verificando = false,
    this.abrindo = false,
    this.erro,
  });
  final VersaoInstalada? instalada;
  final VersaoPublicada? publicada;
  final SituacaoAtualizacao situacao;
  final bool verificando, abrindo;
  final String? erro;
  bool get disponivel =>
      situacao == SituacaoAtualizacao.disponivel && publicada?.apk != null;
  EstadoAtualizacao copiar({
    VersaoInstalada? instalada,
    VersaoPublicada? publicada,
    SituacaoAtualizacao? situacao,
    bool? verificando,
    bool? abrindo,
    String? erro,
    bool limparErro = false,
  }) => EstadoAtualizacao(
    instalada: instalada ?? this.instalada,
    publicada: publicada ?? this.publicada,
    situacao: situacao ?? this.situacao,
    verificando: verificando ?? this.verificando,
    abrindo: abrindo ?? this.abrindo,
    erro: limparErro ? null : erro ?? this.erro,
  );
}

class AtualizacaoController extends Notifier<EstadoAtualizacao> {
  bool _consultado = false, _vivo = true;
  int _geracao = 0;
  @override
  EstadoAtualizacao build() {
    _vivo = true;
    ref.onDispose(() {
      _vivo = false;
      _geracao++;
    });
    return const EstadoAtualizacao();
  }

  Future<void> verificar({bool automatico = false}) async {
    if (!ref.read(atualizacaoSuportadaProvider) ||
        state.verificando ||
        state.abrindo ||
        (automatico && _consultado)) {
      return;
    }
    _consultado = true;
    final geracao = ++_geracao;
    final fonte = ref.read(fonteAtualizacaoProvider);
    state = state.copiar(verificando: true, limparErro: true);
    try {
      final instalada = await fonte.instalada();
      if (!_vivo || geracao != _geracao) return;
      final numero = NumeroVersao.ler(instalada.versao);
      if (numero == null) {
        throw const FormatException('Versão instalada desconhecida.');
      }
      state = state.copiar(instalada: instalada);
      final publicada = await fonte.publicada();
      if (!_vivo || geracao != _geracao) return;
      final nova = publicada.numero.maisNovaQue(numero);
      state = state.copiar(
        publicada: publicada,
        verificando: false,
        limparErro: true,
        situacao: !nova
            ? SituacaoAtualizacao.atualizado
            : publicada.apk == null
            ? SituacaoAtualizacao.preparando
            : SituacaoAtualizacao.disponivel,
      );
    } catch (_) {
      if (!_vivo || geracao != _geracao) return;
      state = state.copiar(
        verificando: false,
        situacao: state.disponivel
            ? SituacaoAtualizacao.disponivel
            : SituacaoAtualizacao.indisponivel,
        erro: automatico ? null : 'Não foi possível verificar agora. Confira a conexão e tente novamente.',
      );
    }
  }

  Future<void> baixar() async {
    final apk = state.publicada?.apk;
    if (!state.disponivel ||
        apk == null ||
        state.abrindo ||
        state.verificando) {
      return;
    }
    final fonte = ref.read(fonteAtualizacaoProvider);
    final geracao = _geracao;
    state = state.copiar(abrindo: true, limparErro: true);
    try {
      final ok = await fonte.abrir(apk);
      if (!_vivo || geracao != _geracao) return;
      state = state.copiar(
        abrindo: false,
        erro: ok ? null : 'Não foi possível abrir o download. Tente novamente.',
      );
    } catch (_) {
      if (!_vivo || geracao != _geracao) return;
      state = state.copiar(
        abrindo: false,
        erro: 'Não foi possível abrir o download. Tente novamente.',
      );
    }
  }
}

final atualizacaoControllerProvider =
    NotifierProvider<AtualizacaoController, EstadoAtualizacao>(
      AtualizacaoController.new,
    );
