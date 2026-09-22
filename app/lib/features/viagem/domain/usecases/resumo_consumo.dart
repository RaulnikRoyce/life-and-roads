import 'package:life_and_roads/viagem/calculo.dart';

class BarraConsumo {
  const BarraConsumo({required this.registro, required this.fracao});

  final RegistroAbastecimento registro;

  /// 0–1 em relação ao maior R$/km da série.
  final double fracao;
}

class ResumoConsumoResultado {
  const ResumoConsumoResultado({this.media, this.barras = const []});

  final double? media;
  final List<BarraConsumo> barras;
}

/// Série de R$/km dos postos neste aparelho. Sem gráfico de biblioteca.
class ResumoConsumo {
  const ResumoConsumo();

  ResumoConsumoResultado executar(List<RegistroAbastecimento> historico) {
    // O primeiro abastecimento não tem intervalo; fica fora do gráfico.
    final comIntervalo = [
      for (final r in historico)
        if (r.temConsumo) r,
    ];
    if (comIntervalo.isEmpty) return const ResumoConsumoResultado();
    var max = 0.0;
    for (final r in comIntervalo) {
      if (r.reaisPorKm > max) max = r.reaisPorKm;
    }
    return ResumoConsumoResultado(
      media: custoMedioPorKm(comIntervalo),
      barras: [
        for (final r in comIntervalo)
          BarraConsumo(
            registro: r,
            fracao: max <= 0 ? 0 : (r.reaisPorKm / max).clamp(0, 1),
          ),
      ],
    );
  }
}
