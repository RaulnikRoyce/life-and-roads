import 'package:life_and_roads/viagem/calculo.dart';

class BarraConsumo {
  const BarraConsumo({required this.registro, required this.fracao});

  final RegistroAbastecimento registro;

  /// 0–1 em relação ao maior R$/km da série.
  final double fracao;
}

class ResumoConsumoResultado {
  const ResumoConsumoResultado({
    this.media,
    this.barras = const [],
  });

  final double? media;
  final List<BarraConsumo> barras;
}

/// Série de R$/km dos postos neste aparelho. Sem gráfico de biblioteca.
class ResumoConsumo {
  const ResumoConsumo();

  ResumoConsumoResultado executar(List<RegistroAbastecimento> historico) {
    if (historico.isEmpty) return const ResumoConsumoResultado();
    var max = 0.0;
    for (final r in historico) {
      if (r.reaisPorKm > max) max = r.reaisPorKm;
    }
    return ResumoConsumoResultado(
      media: custoMedioPorKm(historico),
      barras: [
        for (final r in historico)
          BarraConsumo(
            registro: r,
            fracao: max <= 0 ? 0 : (r.reaisPorKm / max).clamp(0, 1),
          ),
      ],
    );
  }
}
