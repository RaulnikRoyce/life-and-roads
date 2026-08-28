import 'package:flutter/material.dart';
import 'package:life_and_roads/tema.dart';

/// Abertura com logomarca e crédito. Em seguida entram as quatro abas.
class TelaAbertura extends StatefulWidget {
  const TelaAbertura({super.key, required this.aoTerminar});

  final VoidCallback aoTerminar;

  static const duracao = Duration(milliseconds: 2500);

  @override
  State<TelaAbertura> createState() => _TelaAberturaState();
}

class _TelaAberturaState extends State<TelaAbertura> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(TelaAbertura.duracao, () {
      if (mounted) widget.aoTerminar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).textTheme.bodyMedium?.color ?? Oficina.mute;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Image.asset(
                'assets/lr.png',
                width: 128,
                height: 128,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'developed by Raulnik Royce',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: mute,
                    letterSpacing: 0.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
