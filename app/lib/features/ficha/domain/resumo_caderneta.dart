/// Quanto tem numa caderneta da nuvem ou do aparelho, para decidir e para
/// mostrar ao piloto os dois lados de um conflito (ADR 0038).
class ResumoCaderneta {
  const ResumoCaderneta({
    this.abastecimentos = 0,
    this.servicos = 0,
    this.pins = 0,
    this.temKmOuCnh = false,
  });

  /// Lê o pacote no formato do `ConteudoCaderneta`.
  factory ResumoCaderneta.de(Map<String, dynamic> conteudo) {
    int conta(Object? lista) => lista is List ? lista.length : 0;
    final extra = conteudo['extra'];
    return ResumoCaderneta(
      abastecimentos: conta(conteudo['abastecimentos']),
      servicos: conta(conteudo['servicos']),
      pins: conta(conteudo['pins']),
      temKmOuCnh: extra is String && extra.isNotEmpty,
    );
  }

  final int abastecimentos;
  final int servicos;
  final int pins;

  /// Km de óleo e corrente ou validade da CNH preenchidos.
  final bool temKmOuCnh;

  /// Sem histórico nenhum. Preço do dia e PSI não contam: sozinhos, não
  /// valem uma pergunta ao piloto.
  bool get vazia =>
      abastecimentos == 0 && servicos == 0 && pins == 0 && !temKmOuCnh;

  /// "3 abastecimentos, 1 serviço e 2 pinos".
  String get texto {
    String item(int n, String um, String varios) => '$n ${n == 1 ? um : varios}';
    final partes = [
      item(abastecimentos, 'abastecimento', 'abastecimentos'),
      item(servicos, 'serviço', 'serviços'),
      item(pins, 'pino', 'pinos'),
    ];
    return '${partes[0]}, ${partes[1]} e ${partes[2]}';
  }
}
