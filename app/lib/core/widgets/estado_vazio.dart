import 'package:flutter/material.dart';
import 'package:life_and_roads/core/widgets/movimento.dart';
import 'package:life_and_roads/tema.dart';

/// Lista sem nada ainda: ícone em marca d'água e uma frase que diz o que
/// fazer. Em vez de um espaço em branco.
class EstadoVazio extends StatelessWidget {
  const EstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    required this.frase,
  });

  final IconData icone;
  final String titulo;
  final String frase;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return EntradaSuave(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Oficina.raio),
          border: Border.all(color: tema.colorScheme.outline),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Positioned(
              right: -8,
              child: Icon(
                icone,
                size: 84,
                color: Oficina.latao.withValues(alpha: 0.12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 72),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(titulo, style: tema.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(frase, style: tema.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
