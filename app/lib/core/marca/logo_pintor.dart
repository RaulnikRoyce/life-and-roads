import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:life_and_roads/core/marca/logo_dados.dart';

/// Lê o `d` gerado em [LogoDados]: só M, L, C e Z absolutos.
Path lerCaminho(String d) {
  final path = Path();
  final it = RegExp(r'[MLCZ]|-?\d+\.?\d*').allMatches(d).map((m) => m[0]!);
  final tokens = it.toList();
  var i = 0;
  double n() => double.parse(tokens[i++]);
  while (i < tokens.length) {
    switch (tokens[i++]) {
      case 'M':
        path.moveTo(n(), n());
      case 'L':
        path.lineTo(n(), n());
      case 'C':
        path.cubicTo(n(), n(), n(), n(), n(), n());
      case 'Z':
        path.close();
    }
  }
  path.fillType = PathFillType.evenOdd;
  return path;
}

/// Caminhos já lidos, uma vez por processo.
final Map<String, Path> _cache = {};
Path _p(TracoLogo t) => _cache.putIfAbsent(t.d, () => lerCaminho(t.d));

/// Trecho de [t] entre [a] e [b], de 0 a 1, com curva suave.
double _fase(
  double t,
  double a,
  double b, [
  Curve curva = Curves.easeOutCubic,
]) {
  if (t <= a) return 0;
  if (t >= b) return 1;
  return curva.transform((t - a) / (b - a));
}

/// Desenha a logo no progresso [t].
///
/// 0,00 a 0,50: os contornos dos dois capacetes e do cabelo se desenham.
/// 0,40 a 0,65: os preenchimentos dos capacetes aparecem.
/// 0,50 a 0,78: o disco vinho abre em círculo a partir do centro, com o anel.
/// 0,66 a 0,90: fitas e textos deslizam para o lugar.
/// 0,82 a 1,00: Instagram, arroba e cidade aparecem.
///
/// Em [t] = 1 é a logo inteira, igual ao desenho original.
class LogoPintor extends CustomPainter {
  const LogoPintor({required this.t, required this.escuro});

  final double t;

  /// No tema escuro o traço inicial é creme para aparecer sobre o fundo.
  final bool escuro;

  @override
  void paint(Canvas canvas, Size size) {
    final escala = size.width / LogoDados.largura;
    final alturaReal = LogoDados.altura * escala;
    canvas.save();
    canvas.translate(0, (size.height - alturaReal) / 2);
    canvas.scale(escala);

    final centro = Offset(LogoDados.largura / 2, LogoDados.altura / 2);

    // Disco e anel, abrindo em círculo.
    final abre = _fase(t, 0.50, 0.78);
    if (abre > 0) {
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: centro, radius: 560 * abre)),
      );
      _preencher(canvas, LogoDados.disco, 1);
      _preencher(canvas, LogoDados.borda, 1);
      canvas.restore();
    }

    // Contornos dos capacetes se desenhando.
    final traco = _fase(t, 0.0, 0.50, Curves.easeInOutCubic);
    final corTraco = escuro ? const Color(0xFFF5F5F5) : const Color(0xFF121212);
    if (traco > 0 && traco < 1) {
      final tinta = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..color = corTraco;
      for (final contorno in [
        LogoDados.capaceteEsquerdo.first,
        LogoDados.capaceteDireito.first,
        LogoDados.cabelo.first,
      ]) {
        _tracar(canvas, _p(contorno), traco, tinta);
      }
    }

    // Preenchimentos dos capacetes.
    final corpo = _fase(t, 0.40, 0.65);
    if (corpo > 0) {
      _preencher(canvas, LogoDados.cabelo, corpo);
      _preencher(canvas, LogoDados.capaceteEsquerdo, corpo);
      _preencher(canvas, LogoDados.capaceteDireito, corpo);
      final tintaPonto = Paint()..color = Colors.black.withValues(alpha: corpo);
      for (final (cx, cy, r) in LogoDados.pontos) {
        canvas.drawCircle(Offset(cx, cy), r, tintaPonto);
      }
    }

    // Fitas e textos deslizando.
    final fitas = _fase(t, 0.66, 0.90);
    if (fitas > 0) {
      final desloca = 60 * (1 - fitas);
      canvas.save();
      canvas.translate(0, -desloca);
      _preencher(canvas, LogoDados.fitaCima, fitas);
      _preencher(canvas, LogoDados.textoCima, fitas);
      canvas.restore();
      canvas.save();
      canvas.translate(0, desloca);
      _preencher(canvas, LogoDados.fitaBaixo, fitas);
      _preencher(canvas, LogoDados.textoBaixo, fitas);
      canvas.restore();
      _preencher(canvas, LogoDados.fitaEsquerda, fitas);
      _preencher(canvas, LogoDados.fitaDireita, fitas);
    }

    // Instagram, arroba e cidade.
    final rodape = _fase(t, 0.82, 1.0);
    if (rodape > 0) {
      _preencher(canvas, LogoDados.instagram, rodape);
      _preencher(canvas, LogoDados.handle, rodape);
      _preencher(canvas, LogoDados.cidade, rodape);
    }

    canvas.restore();
  }

  void _preencher(Canvas canvas, List<TracoLogo> tracos, double alpha) {
    for (final tr in tracos) {
      final path = _p(tr);
      canvas.drawPath(
        path,
        Paint()..color = Color(tr.cor).withValues(alpha: alpha),
      );
      final contorno = tr.contorno;
      if (contorno != null && tr.largura > 0) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = tr.largura
            ..color = Color(contorno).withValues(alpha: alpha),
        );
      }
    }
  }

  /// Desenha só a fração [fracao] do comprimento de cada subcaminho.
  void _tracar(Canvas canvas, Path path, double fracao, Paint tinta) {
    for (final ui.PathMetric m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * fracao), tinta);
    }
  }

  @override
  bool shouldRepaint(LogoPintor antigo) =>
      antigo.t != t || antigo.escuro != escuro;
}

/// A logo parada, inteira. Barra superior e onde mais precisar.
class LogoMarca extends StatelessWidget {
  const LogoMarca({super.key, required this.tamanho});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      size: Size(tamanho, tamanho * LogoDados.altura / LogoDados.largura),
      painter: LogoPintor(t: 1, escuro: escuro),
    );
  }
}

/// A logo se desenhando, ligada a uma [Animation] de 0 a 1.
class LogoAnimada extends StatelessWidget {
  const LogoAnimada({
    super.key,
    required this.progresso,
    required this.tamanho,
  });

  final Animation<double> progresso;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: progresso,
      builder: (context, _) => CustomPaint(
        size: Size(tamanho, tamanho * LogoDados.altura / LogoDados.largura),
        painter: LogoPintor(t: progresso.value, escuro: escuro),
      ),
    );
  }
}
