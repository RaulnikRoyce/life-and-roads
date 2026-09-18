/// Dado que veio da API junto com o carimbo `atualizadoEm` do servidor.
///
/// O carimbo diz quando o servidor gravou pela última vez. Guardado no
/// sync store, permite saber se outro aparelho mexeu desde a última
/// sincronização, em vez de tratar qualquer diferença como conflito.
class LidoDoServidor<T> {
  const LidoDoServidor(this.dado, {this.atualizadoEm});

  final T dado;
  final DateTime? atualizadoEm;

  static DateTime? carimbo(Object? bruto) {
    if (bruto is! String || bruto.isEmpty) return null;
    return DateTime.tryParse(bruto)?.toUtc();
  }
}

/// Dois carimbos iguais significam que o servidor não mudou desde então.
/// Sem carimbo de um dos lados, não dá para afirmar; trata como mudou.
bool mesmoCarimbo(DateTime? servidor, DateTime? guardado) {
  if (servidor == null || guardado == null) return false;
  return servidor.toUtc().isAtSameMomentAs(guardado.toUtc());
}
