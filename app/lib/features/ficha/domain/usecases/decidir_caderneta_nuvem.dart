import 'package:life_and_roads/features/ficha/domain/resumo_caderneta.dart';

enum DecisaoNuvem {
  /// Nada nos dois lados.
  nada,

  /// O aparelho manda: a nuvem não existe, está vazia, ou é a mesma que
  /// ele conhece. O envio só sobe se houver mudança.
  enviar,

  /// Os dois lados já têm o mesmo. Só guarda o carimbo da nuvem.
  adotar,

  /// Aparelho vazio: traz a da conta sem perguntar.
  restaurar,

  /// Os dois têm coisa diferente. O piloto escolhe.
  perguntar,
}

/// Ao entrar e ao abrir o app com conta, decide sem perguntar sempre que
/// der (ADR 0038). Só pergunta quando os dois lados têm histórico e ele
/// não é o mesmo, porque aí qualquer escolha automática apagaria algo.
class DecidirCadernetaNuvem {
  const DecidirCadernetaNuvem();

  DecisaoNuvem executar({
    required ResumoCaderneta aparelho,

    /// Null quando a conta ainda não tem caderneta.
    required ResumoCaderneta? nuvem,

    /// O carimbo guardado aqui é o que está na nuvem: a última coisa que
    /// aconteceu lá foi este aparelho mandando ou recebendo.
    required bool mesmoCarimbo,

    /// O conteúdo dos dois lados é igual, mesmo sem carimbo guardado
    /// (celular reinstalado e restaurado do arquivo, por exemplo).
    required bool mesmoConteudo,
  }) {
    if (nuvem == null) {
      return aparelho.vazia ? DecisaoNuvem.nada : DecisaoNuvem.enviar;
    }
    if (mesmoCarimbo) return DecisaoNuvem.enviar;
    if (mesmoConteudo) return DecisaoNuvem.adotar;
    if (aparelho.vazia) return DecisaoNuvem.restaurar;
    if (nuvem.vazia) return DecisaoNuvem.enviar;
    return DecisaoNuvem.perguntar;
  }
}
