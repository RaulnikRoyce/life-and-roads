import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:life_and_roads/core/widgets/movimento.dart';
import 'package:life_and_roads/features/viagem/domain/usecases/resumo_consumo.dart';
import 'package:life_and_roads/tema.dart';

/// O custo por km de cada posto numa linha, do mais antigo ao mais novo,
/// com no máximo os dez últimos. A linha entra da esquerda para a direita
/// uma vez, ao montar e quando chega posto novo. Sem histórico, a base
/// fica pontilhada com a frase de partida no meio.
class GraficoConsumo extends StatelessWidget {
  const GraficoConsumo({super.key, required this.barras, required this.fundo});

  /// Barras como o histórico entrega, do mais novo ao mais antigo.
  final List<BarraConsumo> barras;

  /// Cor do fundo do cartão, para o miolo dos pontos.
  final Color fundo;

  static const altura = 96.0;
  static const maximo = 10;

  /// Os últimos [maximo] postos em ordem cronológica.
  static List<BarraConsumo> pontos(List<BarraConsumo> barras) =>
      barras.take(maximo).toList().reversed.toList();

  /// "dd/mm" de uma data ISO; vazio se não der para ler.
  static String dataCurta(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final serie = pontos(barras);
    final trilho = tema.colorScheme.onSurface.withValues(alpha: 0.12);
    final rotulo = tema.textTheme.labelLarge?.copyWith(
      fontSize: 10,
      letterSpacing: 1.2,
      color: Oficina.mute,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: altura,
          child: Stack(
            fit: StackFit.expand,
            children: [
              TweenAnimationBuilder<double>(
                // Posto novo no fim da série: a linha entra de novo.
                key: ValueKey(serie.isEmpty ? '' : serie.last.registro.em),
                tween: Tween(begin: 0, end: 1),
                duration: Movimento.longo,
                curve: Movimento.curva,
                builder: (context, t, _) => CustomPaint(
                  painter: _GraficoPainter(
                    fracoes: [for (final b in serie) b.fracao],
                    revelado: t,
                    fundo: fundo,
                    trilho: trilho,
                  ),
                ),
              ),
              if (serie.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Registre o primeiro abastecimento para ver o consumo real.',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.bodyMedium?.copyWith(
                        color: Oficina.mute,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (serie.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: serie.length == 1
                ? MainAxisAlignment.center
                : MainAxisAlignment.spaceBetween,
            children: [
              Text(dataCurta(serie.first.registro.em), style: rotulo),
              if (serie.length > 1)
                Text(dataCurta(serie.last.registro.em), style: rotulo),
            ],
          ),
        ],
      ],
    );
  }
}

/// Linha em latão com a área abaixo, pontos com miolo na cor do cartão e a
/// base. [revelado] (0 a 1) é a largura já visível, um clipe que cresce da
/// esquerda para a direita. Um ponto só fica no centro, sobre a base.
class _GraficoPainter extends CustomPainter {
  const _GraficoPainter({
    required this.fracoes,
    required this.revelado,
    required this.fundo,
    required this.trilho,
  });

  final List<double> fracoes;
  final double revelado;
  final Color fundo;
  final Color trilho;

  static const margem = 8.0;
  static const raioPonto = 4.0;
  static const traco = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final base = size.height - margem;
    if (fracoes.isEmpty) {
      _pontilhada(canvas, size.width, base);
      return;
    }
    canvas.drawLine(
      Offset(0, base),
      Offset(size.width, base),
      Paint()
        ..color = trilho
        ..strokeWidth = 1,
    );

    // Recuo do raio nas pontas, para o primeiro e o último ponto não
    // vazarem do cartão.
    final util = size.width - 2 * raioPonto;
    final pontos = <Offset>[
      for (var i = 0; i < fracoes.length; i++)
        Offset(
          fracoes.length == 1
              ? size.width / 2
              : raioPonto + util * i / (fracoes.length - 1),
          margem +
              (1 - fracoes[i].clamp(0.0, 1.0)) * (size.height - 2 * margem),
        ),
    ];

    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(0, 0, size.width * revelado.clamp(0.0, 1.0), size.height),
    );
    if (pontos.length > 1) {
      final linha = Path()..moveTo(pontos.first.dx, pontos.first.dy);
      for (final p in pontos.skip(1)) {
        linha.lineTo(p.dx, p.dy);
      }
      final area = Path.from(linha)
        ..lineTo(pontos.last.dx, base)
        ..lineTo(pontos.first.dx, base)
        ..close();
      canvas.drawPath(
        area,
        Paint()..color = Oficina.latao.withValues(alpha: 0.14),
      );
      canvas.drawPath(
        linha,
        Paint()
          ..color = Oficina.latao
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    final borda = Paint()..color = Oficina.latao;
    final miolo = Paint()..color = fundo;
    for (final p in pontos) {
      canvas.drawCircle(p, raioPonto, borda);
      canvas.drawCircle(p, raioPonto / 2, miolo);
    }
    canvas.restore();
  }

  void _pontilhada(Canvas canvas, double largura, double y) {
    final tinta = Paint()
      ..color = trilho
      ..strokeWidth = 1;
    for (var x = 0.0; x < largura; x += traco * 2) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + traco, largura), y),
        tinta,
      );
    }
  }

  @override
  bool shouldRepaint(_GraficoPainter old) =>
      old.revelado != revelado ||
      old.fundo != fundo ||
      old.trilho != trilho ||
      !listEquals(old.fracoes, fracoes);
}
