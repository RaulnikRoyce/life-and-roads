import 'package:life_and_roads/features/ficha/domain/resumo_caderneta.dart';

/// Os dois lados de uma caderneta que divergiu, para o piloto escolher.
class ConflitoCadernetaNuvem {
  const ConflitoCadernetaNuvem({
    required this.aparelho,
    required this.nuvem,
    this.nuvemEm,
  });

  final ResumoCaderneta aparelho;
  final ResumoCaderneta nuvem;

  /// Quando a da conta foi gravada.
  final DateTime? nuvemEm;
}

/// O que a Ficha precisa saber da caderneta na nuvem (ADR 0038).
class SituacaoNuvem {
  const SituacaoNuvem({
    this.logado = false,
    this.ligada = true,
    this.precisaAceite = false,
    this.conflito,
    this.guardadaEm,
    this.restaurou = false,
    this.offline = false,
  });

  final bool logado;
  final bool ligada;

  /// Conta sem o aceite da versão atual dos termos. Nada sobe até responder.
  final bool precisaAceite;

  final ConflitoCadernetaNuvem? conflito;

  /// Carimbo da última gravação conhecida na conta.
  final DateTime? guardadaEm;

  /// A caderneta da conta acabou de vir para o aparelho.
  final bool restaurou;

  /// A nuvem não respondeu desta vez.
  final bool offline;

  SituacaoNuvem copiarCom({DateTime? guardadaEm}) {
    return SituacaoNuvem(
      logado: logado,
      ligada: ligada,
      precisaAceite: precisaAceite,
      conflito: conflito,
      guardadaEm: guardadaEm ?? this.guardadaEm,
      offline: offline,
    );
  }
}
