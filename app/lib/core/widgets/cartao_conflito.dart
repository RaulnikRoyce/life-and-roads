import 'package:flutter/material.dart';
import 'package:life_and_roads/tema.dart';

/// Aviso quando a caderneta neste aparelho e a do servidor divergem.
class CartaoConflito extends StatelessWidget {
  const CartaoConflito({
    super.key,
    required this.titulo,
    required this.resumoRemoto,
    required this.aoManter,
    required this.aoUsarServidor,
    this.resumoLocal,
    this.ocupado = false,
  });

  final String titulo;
  final String resumoRemoto;

  /// O que tem neste aparelho, quando ajuda a escolher.
  final String? resumoLocal;

  /// Esperando a API: os botões ficam parados.
  final bool ocupado;
  final VoidCallback aoManter;
  final VoidCallback aoUsarServidor;

  @override
  Widget build(BuildContext context) {
    return CartaoOficina(
      destaque: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'No servidor: $resumoRemoto. Foi alterada em outro aparelho.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (resumoLocal != null) ...[
            const SizedBox(height: 4),
            Text(
              'Neste aparelho: $resumoLocal.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: ocupado ? null : aoManter,
                  child: const Text('Manter esta'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: ocupado ? null : aoUsarServidor,
                  child: const Text('Usar a do servidor'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
