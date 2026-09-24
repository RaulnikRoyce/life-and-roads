import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_and_roads/api.dart';
import 'package:life_and_roads/core/backup/backup_nuvem.dart';
import 'package:life_and_roads/features/ficha/data/caderneta_nuvem_repository.dart';
import 'package:life_and_roads/features/ficha/domain/situacao_nuvem.dart';
import 'package:life_and_roads/features/ficha/presentation/ficha_controller.dart';
import 'package:life_and_roads/features/manutencao/presentation/avisos_controller.dart';
import 'package:life_and_roads/features/manutencao/presentation/manutencao_controller.dart';
import 'package:life_and_roads/features/mapa/presentation/mapa_controller.dart';
import 'package:life_and_roads/features/viagem/presentation/viagem_controller.dart';

final cadernetaNuvemRepositoryProvider = Provider<CadernetaNuvemRepository>(
  (ref) => CadernetaNuvemRepository(
    backup: ref.watch(backupNuvemProvider),
    auth: ref.watch(authRepositoryProvider),
  ),
);

class NuvemEstado {
  const NuvemEstado({
    this.situacao = const SituacaoNuvem(),
    this.ocupado = false,
    this.aviso,
    this.erro,
  });

  final SituacaoNuvem situacao;

  /// Um botão do cartão ou do interruptor está esperando a API.
  final bool ocupado;
  final String? aviso;
  final String? erro;

  NuvemEstado copiarCom({
    SituacaoNuvem? situacao,
    bool? ocupado,
    String? aviso,
    String? erro,
    bool limparAviso = false,
    bool limparErro = false,
  }) {
    return NuvemEstado(
      situacao: situacao ?? this.situacao,
      ocupado: ocupado ?? this.ocupado,
      aviso: limparAviso ? null : (aviso ?? this.aviso),
      erro: limparErro ? null : (erro ?? this.erro),
    );
  }
}

/// A caderneta na nuvem vista pela Ficha: o cartão do aceite, o cartão de
/// conflito e o interruptor do bloco Conta (ADR 0038).
class CadernetaNuvemController extends Notifier<NuvemEstado> {
  CadernetaNuvemRepository get _repo =>
      ref.read(cadernetaNuvemRepositoryProvider);

  Future<void>? _verificando;

  @override
  NuvemEstado build() {
    final backup = ref.watch(backupNuvemProvider);
    void aoGravar() {
      final carimbo = backup.ultimo.value;
      final em = carimbo == null ? null : DateTime.tryParse(carimbo)?.toLocal();
      if (em == null) return;
      state = state.copiarCom(situacao: state.situacao.copiarCom(guardadaEm: em));
    }

    // Um envio por trás bateu em 409: pergunta sem esperar a próxima abertura.
    void aoConflito() {
      if (backup.conflito.value) unawaited(verificar());
    }

    backup.ultimo.addListener(aoGravar);
    backup.conflito.addListener(aoConflito);
    ref.onDispose(() {
      backup.ultimo.removeListener(aoGravar);
      backup.conflito.removeListener(aoConflito);
    });
    return const NuvemEstado();
  }

  /// Chamado depois que a ficha carrega, para o PSI ter onde entrar se a
  /// caderneta vier da conta. Pedidos juntos viram um só.
  Future<void> verificar() {
    return _verificando ??= _verificar().whenComplete(() => _verificando = null);
  }

  Future<void> _verificar() async {
    try {
      await _aplicar(await _repo.verificar());
    } catch (_) {
      // Leitura por trás: falha fica para a próxima abertura.
    }
  }

  Future<void> registrarAceiteDoLogin(String? versao) =>
      _repo.registrarAceiteDoLogin(versao);

  Future<void> aceitar() => _acao(
    _repo.aceitar,
    falha: 'Sem resposta da API. O aceite não foi registrado.',
  );

  /// Botão "Desligar" do cartão e interruptor desligado.
  Future<void> desligar() => _acao(
    _repo.desligar,
    aviso: 'Caderneta na nuvem desligada. A cópia da conta foi apagada.',
    falha: 'Sem resposta da API. A caderneta na nuvem continua ligada.',
  );

  Future<void> ligar() => _acao(_repo.ligar, falha: 'Sem resposta da API.');

  Future<void> manterAparelho() => _acao(
    _repo.manterAparelho,
    aviso: 'A caderneta deste aparelho foi para a conta.',
    falha: 'Sem resposta da API. Nada mudou.',
  );

  Future<void> usarDaConta() => _acao(
    _repo.usarDaConta,
    falha: 'Sem resposta da API. Nada mudou.',
  );

  Future<void> _acao(
    Future<SituacaoNuvem> Function() fazer, {
    String? aviso,
    required String falha,
  }) async {
    if (state.ocupado) return;
    state = state.copiarCom(ocupado: true, limparAviso: true, limparErro: true);
    try {
      await _aplicar(await fazer(), aviso: aviso);
    } on FalhaApi catch (e) {
      state = state.copiarCom(ocupado: false, erro: e.mensagem);
    } catch (_) {
      state = state.copiarCom(ocupado: false, erro: falha);
    }
  }

  Future<void> _aplicar(SituacaoNuvem situacao, {String? aviso}) async {
    state = NuvemEstado(
      situacao: situacao,
      aviso: situacao.restaurou
          ? 'A caderneta da conta veio para este aparelho.'
          : aviso,
    );
    if (situacao.restaurou) await _relerTelas();
  }

  /// A caderneta trocou por baixo das telas: cada uma relê o aparelho.
  Future<void> _relerTelas() async {
    await ref.read(fichaControllerProvider.notifier).relerDoAparelho();
    await ref.read(viagemControllerProvider.notifier).carregar();
    await ref.read(manutencaoControllerProvider.notifier).carregar();
    await ref.read(mapaControllerProvider.notifier).carregar();
    await ref.read(avisosControllerProvider.notifier).recarregar();
  }
}

final cadernetaNuvemControllerProvider =
    NotifierProvider<CadernetaNuvemController, NuvemEstado>(
      CadernetaNuvemController.new,
    );
