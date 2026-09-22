import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:life_and_roads/core/widgets/movimento.dart';
import 'package:life_and_roads/tema.dart';
import 'package:life_and_roads/viagem/calculo.dart';

/// O resultado da viagem como cupom de posto: bordas picotadas em cima e
/// embaixo, faixa em latão à esquerda, litros em número grande, o valor e,
/// depois de uma linha tracejada, se cabe no tanque.
class BilheteViagem extends StatelessWidget {
  const BilheteViagem({
    super.key,
    required this.km,
    required this.combustivel,
    required this.litros,
    required this.reais,
    this.avisoTanque,
  });

  final double km;
  final Combustivel combustivel;
  final double litros;
  final double reais;

  /// "Cabe no tanque de 16,1 L." ou "Ultrapassa o tanque de ...". Sem
  /// tanque na ficha, nada.
  final String? avisoTanque;

  /// "300" ou, abaixo de 10, "7,5".
  static String kmTexto(double v) =>
      v < 10 ? v.toStringAsFixed(1).replaceAll('.', ',') : v.toStringAsFixed(0);

  /// "12,4".
  static String litrosTexto(double v) =>
      v.toStringAsFixed(1).replaceAll('.', ',');

  /// "78,10".
  static String reaisTexto(double v) =>
      v.toStringAsFixed(2).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final mute = tema.textTheme.labelLarge?.copyWith(
      fontSize: 11,
      letterSpacing: 1.4,
      color: Oficina.mute,
    );

    return ClipPath(
      clipper: const _RecortePicotado(),
      child: ColoredBox(
        color: tema.colorScheme.surfaceContainerHighest,
        child: Stack(
          children: [
            Padding(
              // O picote come 6 px em cima e embaixo; o recuo compensa.
              padding: const EdgeInsets.fromLTRB(21, 20, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'VIAGEM DE ${kmTexto(km)} KM',
                    textAlign: TextAlign.center,
                    style: mute?.copyWith(fontSize: 10, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rotuloCombustivel(combustivel).toUpperCase(),
                    textAlign: TextAlign.center,
                    style: mute,
                  ),
                  const SizedBox(height: 6),
                  NumeroAnimado(
                    valor: litros,
                    formatar: (v) => '${litrosTexto(v)} L',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.headlineSmall?.copyWith(
                      fontSize: 40,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 2),
                  NumeroAnimado(
                    valor: reais,
                    formatar: (v) => 'R\$ ${reaisTexto(v)}',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.titleMedium?.copyWith(fontSize: 22),
                  ),
                  if (avisoTanque != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 1,
                      child: CustomPaint(
                        painter: _TracejadoPainter(
                          tema.colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      avisoTanque!,
                      textAlign: TextAlign.center,
                      style: tema.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 3,
              child: ColoredBox(color: Oficina.latao),
            ),
          ],
        ),
      ),
    );
  }
}

/// Retângulo menos meias-circunferências de raio 6 a cada 14 px nas bordas
/// de cima e de baixo, como o picote de um cupom.
class _RecortePicotado extends CustomClipper<Path> {
  const _RecortePicotado();

  static const raio = 6.0;
  static const passo = 14.0;

  @override
  Path getClip(Size size) {
    final furos = Path();
    for (var x = passo / 2; x < size.width; x += passo) {
      furos.addOval(Rect.fromCircle(center: Offset(x, 0), radius: raio));
      furos.addOval(
        Rect.fromCircle(center: Offset(x, size.height), radius: raio),
      );
    }
    return Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      furos,
    );
  }

  @override
  bool shouldReclip(_RecortePicotado old) => false;
}

/// Linha tracejada 4 por 4, como a que separa o cupom da via do cliente.
class _TracejadoPainter extends CustomPainter {
  const _TracejadoPainter(this.cor);

  final Color cor;

  static const traco = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final tinta = Paint()
      ..color = cor
      ..strokeWidth = 1;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += traco * 2) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + traco, size.width), y),
        tinta,
      );
    }
  }

  @override
  bool shouldRepaint(_TracejadoPainter old) => old.cor != cor;
}
